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
  for(int i = 0; i < Count; i+= 1) begin
    regs[i] = '0;
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

  output [29:0] pc_o,

  output [4:0] rd_addr_o,

  // alu
  output alu_cmd_t alu_cmd_o,
  output logic [31:0] alu_lhs_o,
  output logic [31:0] alu_rhs_o,

  // branch
  output branch_alu_cmd_t branch_cmd_o,
  output logic [31:0] branch_lhs_o,
  output logic [31:0] branch_rhs_o,

  output logic branch_o, // Perform a jump or branch

  //TODO y'know, signals

  // Regfile interface
  output logic [4:0] rf_rd0_addr_o,
  output logic [4:0] rf_rd1_addr_o,
  input wire logic [31:0] rf_rd0_data_i,
  input wire logic [31:0] rf_rd0_data_i
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

logic branch_cmd_d;

initial ready_o = '1; //TODO probably needs to be combinatorical
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

  unique case (funct3)
    3'b000: branch_cmd_d = Eq;
    3'b001: branch_cmd_d = Ne;
    3'b100: branch_cmd_d = Lt;
    3'b101: branch_cmd_d = Ge;
    3'b110: branch_cmd_d = Ltu;
    3'b111: branch_cmd_d = Geu;
    default: branch_cmd_d = Eq;
  endcase
end

endmodule


module riscv_dummy
(
  input wire logic clk_i,
  input wire logic reset_ni,

  input wire logic clear_i,

  input wire logic [31:0] instr_i,
  input wire logic instr_valid_i,
  output logic instr_ready_o,

  output logic [31:0] instr_o,
  output logic instr_valid_o,
  input wire logic instr_ready_i
);

logic [31:0] instr_q;
logic instr_valid_q;
logic instr_ready_q;

initial instr_valid_q = '0;
initial instr_ready_q = '1;

assign instr_o = instr_q;
assign instr_valid_o = instr_valid_q;
assign instr_ready_o = instr_ready_q;

always_ff @(posedge clk_i) begin
  if((!reset_ni) || clear_i) begin
    instr_valid_q <= '0;
    instr_ready_q <= '1;
  end else if(instr_valid_i && !instr_valid_o) begin
    instr_q <= instr_i;
    instr_valid_q <= '1;
    instr_ready_q <= '0;
  end else if(instr_valid_q && instr_ready_i) begin
    instr_valid_q <= '0;
    instr_ready_q <= '1;
  end

  //instr_ready_q <= instr_ready_i;
end

endmodule

module riscv_dummy_branch
(
  input wire logic clk_i,
  input wire logic reset_ni,

  input wire logic [31:0] instr_i,
  input wire logic instr_valid_i,
  output logic instr_ready_o,

  output logic pc_valid_o
);

logic [31:0] timer;
initial timer = '0;
always_ff @(posedge clk_i) begin
  timer <= timer + 1;
end

initial pc_valid_o = '0;

assign instr_ready_o = timer >= 8 ? '1 : '0;

always_ff @(posedge clk_i) begin
  if(!reset_ni) begin
    pc_valid_o <= '0;
  end else begin
    if(instr_valid_i && instr_i == 32'hDEADBEEF) begin
      pc_valid_o <= '1;
    end else begin
      pc_valid_o <= '0;
    end
  end
end

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
  output logic wb_i_we_o
);

logic [31:0] ifu_instr;
logic ifu_valid;
logic ifu_ready;

logic ifu_pc_valid;

logic [31:0] dummy_instr;
logic dummy_valid;
logic dummy_ready;

riscv_dummy dummy0
(
  .clk_i,
  .reset_ni,

  .clear_i(ifu_pc_valid),

  .instr_i(ifu_instr),
  .instr_valid_i(ifu_valid),
  .instr_ready_o(ifu_ready),

  .instr_valid_o(dummy_valid),
  .instr_o(dummy_instr),
  .instr_ready_i(dummy_ready)
);

riscv_dummy_branch branch0
(
  .clk_i,
  .reset_ni,

  .instr_i(dummy_instr),
  .instr_valid_i(dummy_valid),
  .instr_ready_o(dummy_ready),

  .pc_valid_o(ifu_pc_valid)
);

riscv_ifu ifu0
(
  .clk_i,
  .reset_ni,

  // Tie ready to high
  .instr_ready_i(ifu_ready),
  .instr_valid_o(ifu_valid),
  .instr_o(ifu_instr),

  .pc_i(1),
  .pc_valid_i(ifu_pc_valid),

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

endmodule
