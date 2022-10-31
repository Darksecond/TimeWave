`default_nettype none

module system_bus
#(
  parameter Followers = 0,
  localparam FollowerBits = $clog2(Followers)
)
(
  bus.follower leader,
  bus.leader followers[0:Followers-1]
);

logic [3:0] tag;
logic [31:0] addr_masked;
logic [FollowerBits-1:0] select;
logic [Followers-1:0] requests;
logic [31:0] read_data [0:Followers-1];

for (genvar i = 0; i < Followers; i = i + 1) begin
  assign requests[i] = followers[i].read_data_valid;
  assign read_data[i] = followers[i].read_data;
end

bus_decoder
#(
  .AddrWidth(32),
  .TagWidth(4),
  .MaskWidth(4)
) decoder0
(
  .addr(leader.addr),
  .tag(tag),
  .addr_masked(addr_masked)
);

priority_encoder
#(
  .Count(Followers)
) encoder0
(
  .requests(requests),
  .select_valid(leader.read_data_valid),
  .select(select)
);

multiplexer
#(
  .SelectBits(FollowerBits),
  .DataWidth(32),
  .Count(Followers)
) mux0
(
  .select(select),
  .data_in(read_data),
  .data_out(leader.read_data)
);

for (genvar i = 0; i < Followers; i = i + 1) begin
  always_comb begin
    followers[i].addr = addr_masked;
    followers[i].write_data = leader.write_data;
    followers[i].byte_enable = leader.byte_enable;
    followers[i].read_req = 0;
    followers[i].write_req = 0;

    if (tag == i) begin
      followers[i].read_req = leader.read_req;
      followers[i].write_req = leader.write_req;
    end
  end
end

endmodule
