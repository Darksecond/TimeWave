typedef enum logic [1:0] {
  Add,
  Sub
} alu_cmd_t;

module alu(
  input alu_cmd_t cmd,

  input [31:0] lhs,
  input [31:0] rhs,

  output wire logic [31:0] res);

always_comb begin
  case (cmd)
    Add: res = lhs + rhs;
    Sub: res = lhs - rhs;
    default: res = 32'h0;
  endcase
end

endmodule
