`default_nettype none

/* verilator lint_off UNUSED */

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

  //csr signals
  output logic csr_valid_o,
  output logic [11:0] csr_o,

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

logic csr_valid_d;
logic [11:0] csr_d;

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

  csr_valid_d = '0;
  csr_d = '0;

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
  7'b0010111: begin // AUIPC
    alu_lhs_d = u_imm;
    alu_rhs_d = {pc_i, 2'b00};
    alu_cmd_d = Add;

    hz_rs1_addr_o = '0;
    hz_rs2_addr_o = '0;
  end
  7'b0010011: begin // ADDI
    if (funct7 == 7'b0100000) begin
      alu_cmd_d = Sra; // Detect SRAI
    end

    alu_rhs_d = i_imm;
  end
  7'b0110011: begin // ADD, SUB, etc
    if (funct7 == 7'b0100000) begin
      alu_cmd_d = Sub; // Detect SUB
    end
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
  7'b1100111: begin // JALR
    branch_alu_lhs_d = '0;
    branch_alu_rhs_d = '0;
    branch_cmd_d = Eq;
    branch_d = '1;

    alu_cmd_d = Add;
    alu_rhs_d = i_imm;

    hz_rs2_addr_o = '0;
  end
  7'b1100011: begin // BEQ/BNE/BLT/BGE/BLTU/BGEU
    branch_d = '1;

    alu_cmd_d = Add;
    alu_lhs_d = {pc_i, 2'b00};
    alu_rhs_d = b_imm;

    rd_addr_d = '0;
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
  7'b0001111: begin // FENCE (No-Op)
    hz_rs1_addr_o = '0;
    hz_rs2_addr_o = '0;
    rd_addr_d = '0;
  end
  7'b1110011: begin // ECALL, EBREAK (No-Op)
    unique case(funct3)
    3'b010: begin // CsrRs
      //TODO We currently only support reading CSRs so rs1 and rs2 can be safely ignored.
      hz_rs1_addr_o = '0;
      hz_rs2_addr_o = '0;

      csr_valid_d = '1;
      csr_d = instr_i[31:20];
    end
    default: begin
      hz_rs1_addr_o = '0;
      hz_rs2_addr_o = '0;
      rd_addr_d = '0;
    end
    endcase
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

    csr_valid_o <= csr_valid_d;
    csr_o <= csr_d;
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
