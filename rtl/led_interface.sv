`default_nettype none

module led_interface
(
  input wire logic clk,
  input wire logic reset_n,

  bus.follower bus,

  output logic [3:0] leds
);

logic read_data_valid_next;
logic [3:0] leds_next;

assign bus.read_data = {28'h0, leds};

always_comb begin
  read_data_valid_next = bus.read_data_valid;
  leds_next = leds;

  read_data_valid_next = bus.read_req;
  if (bus.write_req && bus.byte_enable[0]) begin
    leds_next = bus.write_data[3:0];
  end
end

always_ff @(posedge clk) begin
  if(!reset_n) begin
    bus.read_data_valid <= 1'h0;
    leds <= 4'h0;
  end else begin
    bus.read_data_valid <= read_data_valid_next;
    leds <= leds_next;
  end
end

endmodule
