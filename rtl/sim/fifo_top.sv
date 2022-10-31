
module fifo_top
(
  input wire logic clk,
  input wire logic reset_n,

  input wire logic write_enable,
  input wire logic [31:0] write_data,
  output logic full, //TODO write_ready?

  input wire logic read_enable,
  output logic [31:0] read_data,
  output logic empty //TODO read_ready
);

fifo
#(
  .Width(32),
  .DepthBits(3)
) fifo0
(
  .clk,
  .reset_n,

  .write_enable,
  .write_data,
  .full,

  .read_enable,
  .read_data,
  .empty
);

endmodule
