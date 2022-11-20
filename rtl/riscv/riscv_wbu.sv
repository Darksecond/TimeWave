`default_nettype none

/* verilator lint_off UNUSED */

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
