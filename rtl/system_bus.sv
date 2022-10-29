`default_nettype none

module system_bus
#(
  parameter Followers = 0
)
(
  input wire logic clk,

  bus.follower leader,
  bus.leader followers[0:Followers-1]
);

for (genvar i = 0; i < Followers; i = i + 1) begin
  always_comb begin
    followers[i].addr = leader.addr & {4'h0, 28'h1};
    followers[i].write_data = leader.write_data;
    followers[i].byte_enable = leader.byte_enable;
  end
end

logic [Followers-1:0] data_valid;
for (genvar i = 0; i < Followers; i = i + 1) begin
  assign data_valid[i] = followers[i].read_data_valid;
end
assign leader.read_data_valid = |data_valid;

logic [31:0] read_data [0:Followers-1];
assign read_data[0] = followers[0].read_data;

for (genvar i = 1; i < Followers; i = i + 1) begin
  always_comb begin
    read_data[i] = followers[i].read_data_valid ? followers[i].read_data : read_data[i-1];
  end
end
assign leader.read_data = read_data[Followers-1];

for (genvar i = 0; i < Followers; i = i + 1) begin
  always_comb begin
    followers[i].read_req = 0;
    followers[i].write_req = 0;

    if (leader.addr[31:28] == i+1) begin
      followers[i].read_req = leader.read_req;
      followers[i].write_req = leader.write_req;
    end
  end
end

endmodule
