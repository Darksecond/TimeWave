`default_nettype none

/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSED */

// Instruction Fetch Unit
module riscv_ifu
(
  input wire logic clk_i,
  input wire logic reset_ni,

  // New PC (for jumps and branches)
  // This will invalidate any currently processing instructions
  input wire logic pc_valid_i,
  input wire logic [29:0] pc_i,

  // Interface to IDU
  input wire logic instr_ready_i, //TODO rename to ready_i ?
  output logic instr_valid_o, //TODO rename to valid_o ?
  output logic [31:0] instr_o,
  output logic [29:0] pc_o,

  // Master port
  input wire logic wb_ack_i,
  input wire logic wb_stall_i,
  input wire logic wb_err_i,
  input wire logic [31:0] wb_data_i,
  output logic [31:0] wb_data_o,
  output logic [29:0] wb_addr_o,
  output logic [3:0] wb_sel_o,
  output logic wb_cyc_o,
  output logic wb_stb_o,
  output logic wb_we_o
);

logic [29:0] pc_q;
logic [31:0] instr_q;
logic instr_valid_q;
logic cyc_q;
logic stb_q;
logic invalid_q; // Skip next ack

assign wb_sel_o = '0;
assign wb_data_o = '0;
assign wb_we_o = '0;

assign instr_o = instr_q;
assign instr_valid_o = instr_valid_q;
assign wb_cyc_o = cyc_q;
assign wb_stb_o = stb_q;
assign wb_addr_o = pc_q;

initial pc_q = '0;
initial instr_valid_q = '0;
initial cyc_q = '0;
initial stb_q = '0;
initial invalid_q = '0;

always_ff @(posedge clk_i) begin
  if((!reset_ni) || (!cyc_q) ) begin
    invalid_q <= '0;
  end else if(pc_valid_i) begin
    invalid_q <= '1;
  end
end

always_ff @(posedge clk_i) begin
  if((!reset_ni) || (cyc_q && wb_ack_i)) begin
    cyc_q <= '0;
    stb_q <= '0;
  end else if(!cyc_q && (!instr_valid_o)) begin
    cyc_q <= '1;
    stb_q <= '1;
  end else if(cyc_q) begin
    cyc_q <= '1;
    if(!wb_stall_i) begin
      stb_q <= '0;
    end
  end
end

always_ff @(posedge clk_i) begin
  if(wb_cyc_o && wb_ack_i) begin
    instr_q <= wb_data_i;
    pc_o <= pc_q;
  end
end

always_ff @(posedge clk_i) begin
  if(pc_valid_i) begin
    pc_q <= pc_i;
  end else if(instr_valid_q && instr_ready_i) begin
    pc_q <= pc_q + 1'b1;
  end
end

always_ff @(posedge clk_i) begin
  if((!reset_ni) || pc_valid_i) begin
    instr_valid_q <= '0;
  end else if(wb_cyc_o && wb_ack_i && !invalid_q) begin
    instr_valid_q <= '1;
  end else if(instr_ready_i) begin
    instr_valid_q <= '0;
  end
end

endmodule


module riscv_regfile
(
  input wire logic clk_i,

  // write port
  input wire logic [31:0] w_data_i,
  input wire logic [4:0] w_addr_i,
  input wire logic w_enable_i,

  // read port 0
  input wire logic [4:0] rd0_addr_i,
  output logic [31:0] rd0_data_o,

  // read port 1
  input wire logic [4:0] rd1_addr_i,
  output logic [31:0] rd1_data_o
);

logic [31:0] regs[32];

initial begin
  for(int i = 0; i < 32; i+= 1) begin
    regs[i] = 0;
  end
end

always_comb begin
  rd0_data_o = regs[rd0_addr_i];
  rd1_data_o = regs[rd1_addr_i];
end

always_ff @(posedge clk_i) begin
  if(w_enable_i && w_addr_i != '0) begin
    regs[w_addr_i] <= w_data_i;
  end
end

endmodule;


// Instruction Decode Unit
module riscv_idu
(
  input wire logic clk_i,
  input wire logic reset_ni,

  input wire logic clear_i, // Branch Clear
  input wire logic stall_i, // Hazard stall

  // IFU interface
  output logic ready_o,
  input wire logic valid_i,
  input wire logic [31:0] instr_i,
  input wire logic [29:0] pc_i,

  // EXU interface
  input wire logic ready_i,
  output logic valid_o,

  output logic [29:0] pc_o,

  output logic [4:0] rd_addr_o,

  // alu
  output alu_cmd_t alu_cmd_o,
  output logic [31:0] alu_lhs_o,
  output logic [31:0] alu_rhs_o,

  // branch
  output branch_alu_cmd_t branch_cmd_o,
  output logic [31:0] branch_lhs_o,
  output logic [31:0] branch_rhs_o,

  output logic branch_o, // Perform a jump or branch

  // mem signals
  output logic [31:0] mem_data_o,
  output logic mem_valid_o,
  output logic mem_we_o,
  output logic [2:0] mem_width_o,

  // hazards
  output logic [4:0] hz_rs1_addr_o,
  output logic [4:0] hz_rs2_addr_o,

  // Regfile interface
  output logic [4:0] rf_rd0_addr_o,
  output logic [4:0] rf_rd1_addr_o,
  input wire logic [31:0] rf_rd0_data_i,
  input wire logic [31:0] rf_rd1_data_i
);

logic [6:0] opcode;
logic [4:0] rd;
logic [2:0] funct3;
logic [4:0] rs1;
logic [4:0] rs2;
logic [6:0] funct7;

logic [31:0] i_imm;
logic [31:0] s_imm;
logic [31:0] b_imm;
logic [31:0] u_imm;
logic [31:0] j_imm;

branch_alu_cmd_t branch_cmd_d;
alu_cmd_t alu_cmd_d;

logic [31:0] alu_lhs_d, alu_rhs_d;
logic [31:0] branch_alu_lhs_d, branch_alu_rhs_d;

logic [4:0] rd_addr_d;

logic branch_d;

logic mem_valid_d;
logic [31:0] mem_data_d;
logic mem_we_d;
logic [2:0] mem_width_d;

logic enable;

assign ready_o = (!stall_i) && ready_i;
assign enable = ready_o;

initial valid_o = '0;

always_comb begin
  opcode = instr_i[6:0];
  rd = instr_i[11:7];
  funct3 = instr_i[14:12];
  rs1 = instr_i[19:15];
  rs2 = instr_i[24:20];
  funct7 = instr_i[31:25];

  i_imm = { {20{instr_i[31]}} , instr_i[31:20] };
  s_imm = { {20{instr_i[31]}}, instr_i[31:25], instr_i[11:7] };
  b_imm = { {19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0 };
  u_imm = { instr_i[31:12], 12'b0 };
  j_imm = { {12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0 };
end

always_comb begin
  branch_d = '0;

  mem_valid_d = '0;
  mem_data_d = rf_rd1_data_i;
  mem_width_d = funct3;
  mem_we_d = 0;

  unique case (funct3)
    3'b000: branch_cmd_d = Eq;
    3'b001: branch_cmd_d = Ne;
    3'b100: branch_cmd_d = Lt;
    3'b101: branch_cmd_d = Ge;
    3'b110: branch_cmd_d = Ltu;
    3'b111: branch_cmd_d = Geu;
    default: branch_cmd_d = Eq;
  endcase

  unique case (funct3)
    3'b000: alu_cmd_d = Add;
    3'b001: alu_cmd_d = Sll;
    3'b010: alu_cmd_d = Slt;
    3'b011: alu_cmd_d = Sltu;
    3'b100: alu_cmd_d = Xor;
    3'b101: alu_cmd_d = Srl;
    3'b110: alu_cmd_d = Or;
    3'b111: alu_cmd_d = And;
    default: alu_cmd_d = Add;
  endcase

  rf_rd0_addr_o = rs1;
  rf_rd1_addr_o = rs2;

  alu_lhs_d = rf_rd0_data_i;
  alu_rhs_d = rf_rd1_data_i;

  branch_alu_lhs_d = rf_rd0_data_i;
  branch_alu_rhs_d = rf_rd1_data_i;

  rd_addr_d = rd;

  hz_rs1_addr_o = rs1;
  hz_rs2_addr_o = rs2;

  unique case (opcode)
  7'b0110111: begin // LUI
    alu_lhs_d = u_imm;
    alu_rhs_d = '0;
    alu_cmd_d = Add;

    hz_rs1_addr_o = '0;
    hz_rs2_addr_o = '0;
  end
  7'b0010011: begin // ADDI
    alu_rhs_d = i_imm;
  end
  7'b1101111: begin // JAL
    branch_alu_lhs_d = '0;
    branch_alu_rhs_d = '0;
    branch_cmd_d = Eq;
    branch_d = '1;

    alu_cmd_d = Add;
    alu_lhs_d = {pc_i, 2'b00};
    alu_rhs_d = j_imm;

    hz_rs1_addr_o = '0;
    hz_rs2_addr_o = '0;
  end
  7'b1100011: begin // BEQ/BNE/BLT/BGE/BLTU/BGEU
    branch_d = '1;

    alu_cmd_d = Add;
    alu_lhs_d = {pc_i, 2'b00};
    alu_rhs_d = b_imm;
  end
  7'b0100011: begin // SW,SH,SB
    mem_valid_d = 1'b1;
    mem_we_d = 1'b1;

    alu_cmd_d = Add;
    alu_rhs_d = s_imm;
  end
  7'b0000011: begin // LW, LH, LB, LHU, LBU
    mem_valid_d = 1'b1;
    mem_we_d = 1'b0;

    alu_cmd_d = Add;
    alu_rhs_d = i_imm;
  end
  default: ; // No current error case
  endcase
end

always_ff @(posedge clk_i) begin
  if(enable) begin
    alu_lhs_o <= alu_lhs_d;
    alu_rhs_o <= alu_rhs_d;
    alu_cmd_o <= alu_cmd_d;

    branch_o <= branch_d;
    branch_cmd_o <= branch_cmd_d;
    branch_lhs_o <= branch_alu_lhs_d;
    branch_rhs_o <= branch_alu_rhs_d;

    rd_addr_o <= rd_addr_d;

    pc_o <= pc_i;

    mem_valid_o <= mem_valid_d;
    mem_data_o <= mem_data_d;
    mem_we_o <= mem_we_d;
    mem_width_o <= mem_width_d;
  end
end

always_ff @(posedge clk_i) begin
  if(valid_o && ready_i) begin
    valid_o <= '0;
  end

  if(enable) begin
    valid_o <= valid_i;
  end

  if((!reset_ni) || clear_i) begin
    valid_o <= '0;
  end
end

endmodule

module riscv_exu
(
  input wire logic clk_i,
  input wire logic reset_ni,

  // IDU interface
  output logic ready_o,
  input wire logic valid_i,
  input wire logic [29:0] pc_i,
  input wire logic [4:0] rd_addr_i,

  // alu
  input alu_cmd_t alu_cmd_i,
  input wire logic [31:0] alu_lhs_i,
  input wire logic [31:0] alu_rhs_i,

  // branch
  input branch_alu_cmd_t branch_cmd_i,
  input wire logic [31:0] branch_lhs_i,
  input wire logic [31:0] branch_rhs_i,

  input wire logic branch_i,

  // mem signals
  input wire logic [31:0] mem_data_i,
  input wire logic mem_valid_i,
  input wire logic mem_we_i,
  input wire logic [2:0] mem_width_i,

  // MEM interface
  input wire logic ready_i,
  output logic valid_o,
  output logic [29:0] pc_o,

  output logic [4:0] rd_addr_o,
  output logic [31:0] rd_data_o,

  // mem signals
  output logic [31:0] mem_data_o,
  output logic mem_valid_o,
  output logic mem_we_o,
  output logic [2:0] mem_width_o,

  // Branch (-> IFU)
  output logic branch_valid_o,
  output logic [29:0] branch_addr_o,

  // Hazards
  output logic [4:0] hz_rd_addr_o
);

logic branch_res_d;
logic [29:0] branch_addr_d;

logic [31:0] alu_res_d;
logic branch_valid_d;

logic [4:0] rd_addr_d;
logic [31:0] rd_data_d;

assign ready_o = ready_i;

assign hz_rd_addr_o = valid_i ? rd_addr_i: '0;

initial valid_o = '0;

alu alu0
(
  .cmd_i(alu_cmd_i),
  .lhs_i(alu_lhs_i),
  .rhs_i(alu_rhs_i),
  .res_o(alu_res_d)
);

branch_alu cmp0
(
  .cmd_i(branch_cmd_i),
  .lhs_i(branch_lhs_i),
  .rhs_i(branch_rhs_i),
  .res_o(branch_res_d)
);

always_comb begin
  branch_valid_d = branch_res_d && branch_i && valid_i;
  branch_addr_d = alu_res_d[31:2];
  rd_addr_d = rd_addr_i;
  rd_data_d = branch_i ? ({pc_i, 2'b00} + 32'h4) : alu_res_d;
end

always_ff @(posedge clk_i) begin
  if(valid_o && ready_i) begin
    valid_o <= '0;
  end

  if(ready_o) begin
    valid_o <= valid_i;
  end

  if((!reset_ni)) begin
    valid_o <= '0;
  end
end

always_ff @(posedge clk_i) begin
  if(ready_o) begin
    pc_o <= pc_i;

    branch_valid_o <= branch_valid_d;
    branch_addr_o <= branch_addr_d;

    rd_addr_o <= rd_addr_d;
    rd_data_o <= rd_data_d;

    mem_data_o <= mem_data_i;
    mem_valid_o <= mem_valid_i;
    mem_we_o <= mem_we_i;
    mem_width_o <= mem_width_i;
  end
end

endmodule

module riscv_lsu
(
  input wire logic clk_i,
  input wire logic reset_ni,

  // EXU interface
  output logic ready_o,
  input wire logic valid_i,
  input wire logic [29:0] pc_i,

  input wire logic [4:0] rd_addr_i,
  input wire logic [31:0] rd_data_i,
  
  // mem signals
  input wire logic [31:0] mem_data_i,
  input wire logic mem_valid_i,
  input wire logic mem_we_i,
  input wire logic [2:0] mem_width_i,

  // WBU interface
  input wire logic ready_i,
  output logic valid_o,
  output logic [29:0] pc_o,

  output logic [4:0] rd_addr_o,
  output logic [31:0] rd_data_o,

  // Master port
  input wire logic wb_ack_i,
  input wire logic wb_stall_i,
  input wire logic wb_err_i,
  input wire logic [31:0] wb_data_i,
  output logic [31:0] wb_data_o,
  output logic [29:0] wb_addr_o,
  output logic [3:0] wb_sel_o,
  output logic wb_cyc_o,
  output logic wb_stb_o,
  output logic wb_we_o,

  // Hazards
  output logic [4:0] hz_rd_addr_o
);

logic mem;
logic passthrough;

logic [3:0] wb_sel_d;
logic [31:0] wb_data_d;

logic [3:0] store_byte_select;
logic [31:0] store_byte_data;

logic [3:0] store_short_select;
logic [31:0] store_short_data;

logic [31:0] load_byte_data, load_short_data;
logic [31:0] rd_data_d;

logic [2:0] mem_width_q;
logic [1:0] mem_offset_q;

assign mem = ready_o && valid_i && mem_valid_i;
assign passthrough = ready_o && valid_i && !mem_valid_i;
assign ready_o = ready_i && ( ready_i || (!valid_o) ) && (!wb_cyc_o);

assign hz_rd_addr_o = valid_i ? rd_addr_i: '0;

initial wb_cyc_o = 1'b0;
initial wb_stb_o = 1'b0;
initial valid_o = 1'b0;

always_comb begin
  unique case(rd_data_i[1:0])
  2'b00: begin
    store_byte_select = 4'b0001;
    store_byte_data = {24'b0, mem_data_i[7:0]};
  end
  2'b01: begin
    store_byte_select = 4'b0010;
    store_byte_data = {16'b0, mem_data_i[7:0], 8'b0};
  end
  2'b10: begin
    store_byte_select = 4'b0100;
    store_byte_data = {8'b0, mem_data_i[7:0], 16'b0};
  end
  2'b11: begin
    store_byte_select = 4'b1000;
    store_byte_data = {mem_data_i[7:0], 24'b0};
  end
  default: ;
  endcase

  unique case(rd_data_i[1:0])
  2'b00: begin
    store_short_select = 4'b0011;
    store_short_data = {16'b0, mem_data_i[15:0]};
  end
  2'b10: begin
    store_short_select = 4'b1100;
    store_short_data = {mem_data_i[15:0], 16'b0};
  end
  default: ;
  endcase

  unique case(mem_width_q[1:0]) // MSB is for 'U', not used here
  2'b00: begin // 'B'
    wb_sel_d = store_byte_select;
    wb_data_d = store_byte_data;
  end
  2'b01: begin // 'H'
    wb_sel_d = store_short_select;
    wb_data_d = store_short_data;
  end
  2'b10: begin // 'W'
    wb_sel_d = 4'b1111;
    wb_data_d = mem_data_i;
  end
  default: ;
  endcase
end

always_comb begin
  unique case(mem_offset_q)
  2'b00: begin
    load_byte_data = {24'b0, wb_data_i[7:0]};
  end
  2'b01: begin
    load_byte_data = {24'b0, wb_data_i[15:8]};
  end
  2'b10: begin
    load_byte_data = {24'b0, wb_data_i[23:16]};
  end
  2'b11: begin
    load_byte_data = {24'b0, wb_data_i[31:24]};
  end
  default: ;
  endcase

  unique case(mem_offset_q)
  2'b00: begin
    load_short_data = {16'b0, wb_data_i[15:0]};
  end
  2'b10: begin
    load_short_data = {16'b0, wb_data_i[31:16]};
  end
  default: ;
  endcase

  unique case(mem_width_q) // MSB is for 'U', not used here
  3'b000: begin // 'B'
    rd_data_d = {{24{load_byte_data[7]}}, load_byte_data[7:0]};
  end
  3'b001: begin // 'H'
    rd_data_d = {{16{load_short_data[15]}}, load_short_data[15:0]};
  end
  3'b010: begin // 'W'
    rd_data_d = wb_data_i;
  end
  3'b100: begin // 'BU'
    rd_data_d = load_byte_data;
  end
  3'b101: begin // 'HU'
    rd_data_d = load_short_data;
  end
  default: ;
  endcase
end

always_ff @(posedge clk_i) begin
  if(valid_o && ready_i) begin
    valid_o <= '0;
  end

  if(wb_cyc_o && wb_stb_o && (!wb_stall_i)) begin
    wb_stb_o <= 1'b0;
  end

  if(!reset_ni) begin
    wb_cyc_o <= 1'b0;
    wb_stb_o <= 1'b0;
    valid_o <= 1'b0;
  end else if(passthrough) begin
    wb_cyc_o <= 1'b0;
    wb_stb_o <= 1'b0;
    valid_o <= valid_i;
  end else if(mem) begin
    valid_o <= 1'b0;
    wb_cyc_o <= 1'b1;
    wb_stb_o <= 1'b1;
  end

  if(wb_cyc_o && wb_ack_i) begin
    wb_cyc_o <= 1'b0;
    valid_o <= 1'b1;
    rd_data_o <= rd_data_d;
  end
end

always_ff @(posedge clk_i) begin
  if(passthrough) begin
    pc_o <= pc_i;
    rd_addr_o <= rd_addr_i;
    rd_data_o <= rd_data_i;
  end else if(mem) begin
    pc_o <= pc_i;
    rd_addr_o <= rd_addr_i;

    mem_width_q <= mem_width_i;
    mem_offset_q <= rd_data_i[1:0];
    wb_we_o <= mem_we_i;
    wb_addr_o <= rd_data_i[31:2];
    wb_data_o <= wb_data_d;
    wb_sel_o <= wb_sel_d;
  end
end

endmodule

module riscv_wbu
(
  input wire logic clk_i,
  input wire logic reset_ni,

  // MEM interface
  output logic ready_o,
  input wire logic valid_i,
  input wire logic [29:0] pc_i,

  input wire logic [4:0] rd_addr_i,
  input wire logic [31:0] rd_data_i,

  // Regfile
  output logic rf_w_enable_o,
  output logic [4:0] rf_w_addr_o,
  output logic [31:0] rf_w_data_o,

  // Hazards
  output logic [4:0] hz_rd_addr_o
);

assign hz_rd_addr_o = valid_i ? rd_addr_i: '0;

assign rf_w_enable_o = rd_addr_i != '0 && valid_i;
assign rf_w_addr_o = rd_addr_i;
assign rf_w_data_o = rd_data_i;

assign ready_o = '1;

endmodule

module riscv_hazards
(
  input wire logic [4:0] id_rs1_i, // Decode
  input wire logic [4:0] id_rs2_i, // Decode

  input wire logic [4:0] ex_rd_i, // Execute
  input wire logic [4:0] ls_rd_i, // Load-Store
  input wire logic [4:0] wb_rd_i, // Writeback

  output logic stall_o
);

logic rs1_stall;
logic rs2_stall;

assign rs1_stall = (id_rs1_i != '0) && (id_rs1_i == ex_rd_i || id_rs1_i == ls_rd_i || id_rs1_i == wb_rd_i);
assign rs2_stall = (id_rs2_i != '0) && (id_rs2_i == ex_rd_i || id_rs2_i == ls_rd_i || id_rs2_i == wb_rd_i);
assign stall_o = rs1_stall || rs2_stall;

endmodule

module riscv
(
  input wire logic clk_i,
  input wire logic reset_ni,

  // Instruction Port
  input wire logic wb_i_ack_i,
  input wire logic wb_i_stall_i,
  input wire logic wb_i_err_i,
  input wire logic [31:0] wb_i_data_i,
  output logic [31:0] wb_i_data_o,
  output logic [29:0] wb_i_addr_o,
  output logic [3:0] wb_i_sel_o,
  output logic wb_i_cyc_o,
  output logic wb_i_stb_o,
  output logic wb_i_we_o,

  // Data Port
  input wire logic wb_d_ack_i,
  input wire logic wb_d_stall_i,
  input wire logic wb_d_err_i,
  input wire logic [31:0] wb_d_data_i,
  output logic [31:0] wb_d_data_o,
  output logic [29:0] wb_d_addr_o,
  output logic [3:0] wb_d_sel_o,
  output logic wb_d_cyc_o,
  output logic wb_d_stb_o,
  output logic wb_d_we_o
);

logic if2id_ready;
logic if2id_valid;
logic [29:0] if2id_pc;
logic [31:0] if2id_instr;

logic [4:0] rf_rd0_addr;
logic [4:0] rf_rd1_addr;
logic [31:0] rf_rd0_data;
logic [31:0] rf_rd1_data;
logic rf_w_enable;
logic [4:0] rf_w_addr;
logic [31:0] rf_w_data;

logic [29:0] id2ex_pc;
logic [4:0] id2ex_rd_addr;
alu_cmd_t id2ex_alu_cmd;
logic [31:0] id2ex_alu_lhs;
logic [31:0] id2ex_alu_rhs;
logic [31:0] id2ex_branch_lhs;
logic [31:0] id2ex_branch_rhs;
branch_alu_cmd_t id2ex_branch_cmd;
logic id2ex_branch;
logic id2ex_ready;
logic id2ex_valid;
logic id2ex_mem_valid;
logic [31:0] id2ex_mem_data;
logic id2ex_mem_we;
logic [2:0] id2ex_mem_width;

logic ex2if_branch_valid;
logic [29:0] ex2if_branch_addr;

logic [4:0] hz_id_rs1, hz_id_rs2, hz_ex_rd, hz_ls_rd, hz_wb_rd;
logic hz_stall;

logic ex2ls_ready;
logic ex2ls_valid;
logic [29:0] ex2ls_pc;
logic [4:0] ex2ls_rd_addr;
logic [31:0] ex2ls_rd_data;
logic ex2ls_mem_valid;
logic [31:0] ex2ls_mem_data;
logic ex2ls_mem_we;
logic [2:0] ex2ls_mem_width;

logic ls2wb_ready;
logic ls2wb_valid;
logic [29:0] ls2wb_pc;
logic [4:0] ls2wb_rd_addr;
logic [31:0] ls2wb_rd_data;

riscv_regfile reg0
(
  .clk_i,

  .w_data_i(rf_w_data),
  .w_addr_i(rf_w_addr),
  .w_enable_i(rf_w_enable),

  // read port 0
  .rd0_addr_i(rf_rd0_addr),
  .rd0_data_o(rf_rd0_data),

  // read port 1
  .rd1_addr_i(rf_rd1_addr),
  .rd1_data_o(rf_rd1_data)
);

riscv_hazards hazard0
(
  .id_rs1_i(hz_id_rs1), // Decode
  .id_rs2_i(hz_id_rs2), // Decode

  .ex_rd_i(hz_ex_rd), // Execute
  .ls_rd_i(hz_ls_rd), // Load-Store
  .wb_rd_i(hz_wb_rd), // Writeback

  .stall_o(hz_stall)
);

riscv_ifu ifu0
(
  .clk_i,
  .reset_ni,

  // Tie ready to high
  .instr_ready_i(if2id_ready),
  .instr_valid_o(if2id_valid),
  .instr_o(if2id_instr),
  .pc_o(if2id_pc),

  .pc_i(ex2if_branch_addr),
  .pc_valid_i(ex2if_branch_valid),

  .wb_ack_i(wb_i_ack_i),
  .wb_stall_i(wb_i_stall_i),
  .wb_err_i(wb_i_err_i),
  .wb_data_i(wb_i_data_i),
  .wb_data_o(wb_i_data_o),
  .wb_addr_o(wb_i_addr_o),
  .wb_sel_o(wb_i_sel_o),
  .wb_cyc_o(wb_i_cyc_o),
  .wb_stb_o(wb_i_stb_o),
  .wb_we_o(wb_i_we_o)
);

riscv_idu idu0
(
  .clk_i,
  .reset_ni,

  .clear_i(ex2if_branch_valid),
  .stall_i(hz_stall),

  .ready_o(if2id_ready),
  .valid_i(if2id_valid),
  .instr_i(if2id_instr),
  .pc_i(if2id_pc),

  // EXU interface
  .ready_i(id2ex_ready),
  .valid_o(id2ex_valid),

  .pc_o(id2ex_pc),

  .rd_addr_o(id2ex_rd_addr),

  // alu
  .alu_cmd_o(id2ex_alu_cmd),
  .alu_lhs_o(id2ex_alu_lhs),
  .alu_rhs_o(id2ex_alu_rhs),

  // branch
  .branch_cmd_o(id2ex_branch_cmd),
  .branch_lhs_o(id2ex_branch_lhs),
  .branch_rhs_o(id2ex_branch_rhs),

  .branch_o(id2ex_branch), // Perform a jump or branch

  // mem
  .mem_valid_o(id2ex_mem_valid),
  .mem_data_o(id2ex_mem_data),
  .mem_we_o(id2ex_mem_we),
  .mem_width_o(id2ex_mem_width),

  // hazards
  .hz_rs1_addr_o(hz_id_rs1),
  .hz_rs2_addr_o(hz_id_rs2),

  // Regfile interface
  .rf_rd0_addr_o(rf_rd0_addr),
  .rf_rd1_addr_o(rf_rd1_addr),
  .rf_rd0_data_i(rf_rd0_data),
  .rf_rd1_data_i(rf_rd1_data)
);

riscv_exu exu0
(
  .clk_i,
  .reset_ni,

  // IDU interface
  .ready_o(id2ex_ready),
  .valid_i(id2ex_valid),
  .pc_i(id2ex_pc),
  .rd_addr_i(id2ex_rd_addr),

  // alu
  .alu_cmd_i(id2ex_alu_cmd),
  .alu_lhs_i(id2ex_alu_lhs),
  .alu_rhs_i(id2ex_alu_rhs),

  // branch
  .branch_cmd_i(id2ex_branch_cmd),
  .branch_lhs_i(id2ex_branch_lhs),
  .branch_rhs_i(id2ex_branch_rhs),

  .branch_i(id2ex_branch),

  // mem
  .mem_valid_i(id2ex_mem_valid),
  .mem_data_i(id2ex_mem_data),
  .mem_we_i(id2ex_mem_we),
  .mem_width_i(id2ex_mem_width),

  // MEM interface
  .ready_i(ex2ls_ready),
  .valid_o(ex2ls_valid),
  .pc_o(ex2ls_pc),

  .rd_addr_o(ex2ls_rd_addr),
  .rd_data_o(ex2ls_rd_data),

  // mem
  .mem_valid_o(ex2ls_mem_valid),
  .mem_data_o(ex2ls_mem_data),
  .mem_we_o(ex2ls_mem_we),
  .mem_width_o(ex2ls_mem_width),

  // Branch (-> IFU)
  .branch_valid_o(ex2if_branch_valid),
  .branch_addr_o(ex2if_branch_addr),

  // Hazards
  .hz_rd_addr_o(hz_ex_rd)
);

riscv_lsu lsu0
(
  .clk_i,
  .reset_ni,

  // EXU interface
  .ready_o(ex2ls_ready),
  .valid_i(ex2ls_valid),
  .pc_i(ex2ls_pc),

  .rd_addr_i(ex2ls_rd_addr),
  .rd_data_i(ex2ls_rd_data),

  // mem
  .mem_valid_i(ex2ls_mem_valid),
  .mem_data_i(ex2ls_mem_data),
  .mem_we_i(ex2ls_mem_we),
  .mem_width_i(ex2ls_mem_width),

  // WBU interface
  .ready_i(ls2wb_ready),
  .valid_o(ls2wb_valid),
  .pc_o(ls2wb_pc),

  .rd_addr_o(ls2wb_rd_addr),
  .rd_data_o(ls2wb_rd_data),

  // Bus master
  .wb_ack_i(wb_d_ack_i),
  .wb_stall_i(wb_d_stall_i),
  .wb_err_i(wb_d_err_i),
  .wb_data_i(wb_d_data_i),
  .wb_data_o(wb_d_data_o),
  .wb_addr_o(wb_d_addr_o),
  .wb_sel_o(wb_d_sel_o),
  .wb_cyc_o(wb_d_cyc_o),
  .wb_stb_o(wb_d_stb_o),
  .wb_we_o(wb_d_we_o),

  // Hazards
  .hz_rd_addr_o(hz_ls_rd)
);

riscv_wbu wbu0
(
  .clk_i,
  .reset_ni,

  // MEM interface
  .ready_o(ls2wb_ready),
  .valid_i(ls2wb_valid),
  .pc_i(ls2wb_pc),

  .rd_addr_i(ls2wb_rd_addr),
  .rd_data_i(ls2wb_rd_data),

  // Regfile
  .rf_w_enable_o(rf_w_enable),
  .rf_w_addr_o(rf_w_addr),
  .rf_w_data_o(rf_w_data),

  // Hazards
  .hz_rd_addr_o(hz_wb_rd)
);

endmodule
