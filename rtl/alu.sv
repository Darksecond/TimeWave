module alu(
  input [1:0] cmd,

  input [31:0] lhs,
  input [31:0] rhs,

  output wire logic [31:0] res);

always_comb begin
  case (cmd)
    0: res = lhs + rhs;
    1: res = lhs - rhs;
    default: res = 32'h0;
  endcase
end

endmodule
