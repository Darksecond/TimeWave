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
bus led_bus();
bus rom_bus();

led_interface led1(
  .clk(clk),
  .reset_n(reset_n),

  .write_req(led_bus.follower.write_req),
  .write_data(led_bus.follower.write_data),
  .byte_enable(led_bus.follower.byte_enable),
  .read_req(led_bus.follower.read_req),
  .read_data(led_bus.follower.read_data),
  .read_data_valid(led_bus.follower.read_data_valid),

  .leds(leds)
);

rom #(
  .Contents("led.mem"),
  .AddrWidth(32),
  .DataWidth(32),
  .Depth(5)
) rom1
(
  .clk(clk),

  .addr(rom_bus.follower.addr),
  .read_req(rom_bus.follower.read_req),
  .read_data(rom_bus.follower.read_data),
  .read_data_valid(rom_bus.follower.read_data_valid)
);

system_bus system_bus0(
  .clk(clk),

  .leader(leader_bus.follower),
  .led(led_bus.leader),
  .rom(rom_bus.leader)
);

always_comb begin
  state_next = state;
  value_next = value;

  case (state)
    2'h0: begin
      leader_bus.leader.addr = 32'h20000000;
      leader_bus.leader.read_req = 1;
      state_next = 2'h1;
    end
    2'h1: begin
      if (leader_bus.leader.read_data_valid)
        value_next = leader_bus.leader.read_data;
        state_next = 2'h2;
    end
    2'h2: begin
      leader_bus.leader.addr = 32'h10000000;
      leader_bus.leader.byte_enable = 4'h1;
      leader_bus.leader.write_req = 1;
      leader_bus.leader.write_data = value;
    end
    default: ;
  endcase
end

always_ff @(posedge clk) begin
  state <= state_next;
  value <= value_next;
end

endmodule
