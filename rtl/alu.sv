module alu(
  input [31:0] lhs,
  input [31:0] rhs,
  output wire [31:0] res);

assign res = lhs + rhs;

endmodule
