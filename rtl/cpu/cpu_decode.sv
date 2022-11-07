`default_nettype none

module cpu_decode
(
  input wire logic clk,
  input wire logic reset_n,

  input wire logic [31:0] instr_i,

  // rs1+rs2
  output logic [4:0] rs1_o,
  output logic [4:0] rs2_o
);

assign rs1_o = instr_i[19:15];
assign rs2_o = instr_i[24:20];

endmodule
