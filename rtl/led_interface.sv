`default_nettype none

module led_interface
#(
  localparam DataWidth = 32,
  localparam AddrWidth = 32,
  localparam SelWidth = DataWidth / 8
)
(
  input wire logic clk,
  input wire logic reset_n,

  output logic [DataWidth-1:0] bus_data_s,
  output logic bus_ack,
  output logic bus_stall,
  output logic bus_err,

  input wire logic [DataWidth-1:0] bus_data_m,
  input wire logic [AddrWidth-1:0] bus_addr,
  input wire logic [SelWidth-1:0] bus_sel,
  input wire logic bus_cyc,
  input wire logic bus_stb,
  input wire logic bus_we,

  output logic [3:0] leds
);

logic [3:0] leds_next;

initial begin
  leds = '0;
  bus_ack = '0;
end

always_comb begin
  bus_data_s = {28'h0, leds};
  bus_stall = '0;
  bus_err = '0;

  leds_next = leds;

  if (bus_stb && bus_we && bus_sel[0]) begin
    leds_next = bus_data_m[3:0];
  end
end

always_ff @(posedge clk) begin
  if(!reset_n) begin
    leds <= '0;
    bus_ack <= '0;
  end else begin
    leds <= leds_next;
    bus_ack <= bus_stb;
  end
end

endmodule
