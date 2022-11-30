`default_nettype none

module wb_master_tb
#(
  parameter DataWidth = 32,
  parameter AddrWidth = 30,

  localparam SelWidth = DataWidth / 8
)
(
  input wire logic clk_i,
  input wire logic reset_ni,

  input wire logic [DataWidth-1:0] wb_data_i,
  input wire logic wb_ack_i,
  input wire logic wb_stall_i,
  input wire logic wb_err_i,

  input wire logic [DataWidth-1:0] wb_data_o,
  input wire logic [AddrWidth-1:0] wb_addr_o,
  input wire logic [SelWidth-1:0] wb_sel_o,
  input wire logic wb_cyc_o,
  input wire logic wb_stb_o,
  input wire logic wb_we_o
);

endmodule
