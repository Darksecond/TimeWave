`default_nettype none

module led_interface_top(
  input wire logic clk,
  input wire logic reset_n,

  output wire logic [3:0] leds
);

logic [31:0] counter;
logic [31:0] counter_next;

logic write_req;
logic [31:0] write_data;

logic read_req;

led_interface led0(
  .clk(clk),
  .reset_n(reset_n),
  .write_req(1),
  .write_data({28'h0, counter[24:21]}),
  .byte_enable(4'h1),
  .read_req(0),
  .leds(leds)
);

always_comb begin
  counter_next = counter + 1;
end

always_ff @(posedge clk) begin
  counter <= counter_next;
end

endmodule
