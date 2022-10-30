`default_nettype none

module led_interface_top(
  input wire logic clk,
  input wire logic reset_n,

  output wire logic [3:0] leds
);

logic [1:0] state = 0;
logic [1:0] state_next;

logic [31:0] value;
logic [31:0] value_next;

bus leader_bus();
bus followers[0:2];

led_interface led1(
  .clk(clk),
  .reset_n(reset_n),

  .bus(followers[1].follower),
  .leds(leds)
);

rom #(
  .Contents("led.mem"),
  .Depth(5)
) rom1
(
  .clk(clk),
  .bus(followers[2].follower)
);

system_bus
#(
  .Followers(3)
) system_bus0
(
  .leader(leader_bus.follower),
  .followers(followers)
);

always_comb begin
  state_next = state;
  value_next = value;

  leader_bus.addr = 0;
  leader_bus.read_req = 0;
  leader_bus.write_req = 0;
  leader_bus.byte_enable = 0;
  leader_bus.write_data = 0;

  case (state)
    2'h0: begin
      leader_bus.addr = 32'h20000000;
      leader_bus.read_req = 1;
      state_next = 2'h1;
    end
    2'h1: begin
      if (leader_bus.read_data_valid)
        value_next = leader_bus.read_data;
        state_next = 2'h2;
    end
    2'h2: begin
      leader_bus.addr = 32'h10000000;
      leader_bus.byte_enable = 4'h1;
      leader_bus.write_req = 1;
      leader_bus.write_data = value;
    end
    default: ;
  endcase
end

always_ff @(posedge clk) begin
  state <= state_next;
  value <= value_next;
end

endmodule
