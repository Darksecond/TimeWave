`default_nettype none

/* verilator lint_off UNUSED */

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
