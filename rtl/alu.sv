`default_nettype none

/* verilator lint_off DECLFILENAME */

typedef enum logic [2:0] {
  Add,
  Sub,
  And,
  Or,
  Xor,
  Sll,
  Srl,
  Sra
} alu_cmd_t;

module alu
(
  input alu_cmd_t cmd_i,
  input wire logic [31:0] lhs_i,
  input wire logic [31:0] rhs_i,
  output logic [31:0] res_o
);

logic [4:0] shamt;

assign shamt = rhs[4:0];

always_comb begin
  case (cmd)
    Add: res_o = lhs_i + rhs_i;
    Sub: res_o = lhs_i - rhs_i;
    And: res_o = lhs_i & rhs_i;
    Or: res_o = lhs_i | rhs_i;
    Xor: res_o = lhs_i ^ rhs_i;
    Sll: res_o = lhs << shamt;
    Srl: res_o = lhs >> shamt;
    Sra: res_o = $signed(lhs) >>> shamt;
    default: res_o = 32'h0;
  endcase
end

endmodule

typedef enum logic [2:0] {
  Eq,
  Ne,
  Lt,
  Ltu,
  Ge,
  Geu
} branch_alu_cmd_t;

module branch_alu
(
  input alu_cmd_t cmd_i,
  input wire logic [31:0] lhs_i,
  input wire logic [31:0] rhs_i,
  output logic [31:0] res_o
);

always_comb begin
  case (cmd)
    Eq: res_o = lhs_i == rhs_i ? 1'b1 : 1'b0;
    Ne: res_o = lhs_i != rhs_i ? 1'b1 : 1'b0;
    Lt: res_o = $signed(lhs_i) < $signed(rhs_i) ? 1'b1 : 1'b0;
    Ltu: res_o = lhs_i < rhs_i ? 1'b1 : 1'b0;
    Ge: res_o = $signed(lhs_i) >= $signed(rhs_i) ? 1'b1 : 1'b0;
    Geu: res_o = lhs_i >= rhs_i ? 1'b1 : 1'b0;
    default: res_o = 32'h0;
  endcase
end

endmodule
