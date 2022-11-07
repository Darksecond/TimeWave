`default_nettype none

module cpu_execute
(
  input wire logic clk,
  input wire logic reset_n,

  input wire logic [31:0] instr_i,

  input wire logic [31:0] rs1_data_i,
  input wire logic [31:0] rs2_data_i,

  output logic [31:0] rd_data_o
);

logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;

assign opcode = instr_i[6:0];
assign funct3 = instr_i[14:12];
assign funct7 = instr_i[31:25];

always_ff @(posedge clk) begin
  rd_data_o <= rs1_data_i + rs2_data_i;
end

endmodule
