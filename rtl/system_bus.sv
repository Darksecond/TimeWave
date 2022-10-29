`default_nettype none

module system_bus
(
  input wire logic clk,

  bus.follower leader,
  bus.leader led,
  bus.leader rom
);

always_comb begin
  led.addr = leader.addr & {4'h0, 28'h1};
  rom.addr = leader.addr & {4'h0, 28'h1};

  led.write_data = leader.write_data;
  rom.write_data = leader.write_data;

  led.byte_enable = leader.byte_enable;
  rom.byte_enable = leader.byte_enable;

  leader.read_data_valid = rom.read_data_valid | led.read_data_valid;
  leader.read_data = rom.read_data_valid ? rom.read_data : led.read_data;

  led.read_req = 0;
  led.write_req = 0;

  rom.read_req = 0;
  rom.write_req = 0;

  case (leader.addr[31:28])
    4'h1: led.read_req = leader.read_req;
    4'h2: rom.read_req = leader.read_req;
    default: ;
  endcase

  case (leader.addr[31:28])
    4'h1: led.write_req = leader.write_req;
    4'h2: rom.write_req = leader.write_req;
    default: ;
  endcase
end

always_ff @(posedge clk) begin
end

endmodule
