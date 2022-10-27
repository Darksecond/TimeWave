`default_nettype none

module led_interface_top(
  input wire logic clk,
  input wire logic reset_n,

  output wire logic [3:0] leds
);

logic led_write_req;
logic [31:0] led_write_data;

logic [31:0] rom_read_data;
logic rom_read_data_valid;

assign led_write_data = rom_read_data;
assign led_write_req = rom_read_data_valid;

rom #(
  .Contents("led.mem"),
  .AddrWidth(32),
  .DataWidth(32),
  .Depth(5)
) rom0
(
  .clk(clk),
  .addr(32'h0),
  .read_req(1),
  .read_data(rom_read_data),
  .read_data_valid(rom_read_data_valid)
);

led_interface led0(
  .clk(clk),
  .reset_n(reset_n),
  .write_req(led_write_req),
  .write_data(led_write_data),
  .byte_enable(4'h1),
  .read_req(0),
  .leds(leds)
);

always_comb begin
end

always_ff @(posedge clk) begin
end

endmodule
