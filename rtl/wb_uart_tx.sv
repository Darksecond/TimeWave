`default_nettype none

/* verilator lint_off UNUSED */

module wb_uart_tx
#(
  parameter BaudRate = 57600,
  parameter ClockFreq = 100_000_000 // 100MHz
)
(
  input wire logic clk_i,

  output logic [31:0] wb_data_o,
  output logic wb_ack_o,
  output logic wb_stall_o,
  output logic wb_err_o,
  input wire logic [31:0] wb_data_i,
  input wire logic [29:0] wb_addr_i,
  input wire logic [3:0] wb_sel_i,
  input wire logic wb_cyc_i,
  input wire logic wb_stb_i,
  input wire logic wb_we_i,

  output logic tx_o
);

logic uart_ready;
logic uart_valid;

assign wb_err_o = '0;
assign wb_stall_o = '0;
assign wb_data_o = {23'b0, uart_ready, 8'b0};
assign uart_valid = wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0];

initial wb_ack_o = '0;

uart_tx
#(
  .BaudRate(BaudRate),
  .ClockFreq(ClockFreq)
) uart0
(
  .clk_i(clk_i),
  .valid_i(uart_valid),
  .ready_o(uart_ready),
  .data_i(wb_data_i[7:0]),
  .tx_o(tx_o)
);

always_ff @(posedge clk_i) begin
  wb_ack_o <= wb_cyc_i && wb_stb_i;
end

endmodule: wb_uart_tx
