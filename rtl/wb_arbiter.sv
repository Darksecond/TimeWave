`default_nettype none

module wb_arbiter
#(
  parameter DataWidth = 32,
  parameter AddrWidth = 32,
  parameter Count = 0,

  localparam SelWidth = DataWidth / 8
)
(
  input wire logic clk,
  input wire logic reset_n,

  wb_bus.follower leaders [0:Count-1],
  wb_bus.leader follower
);

logic [Count-1:0] grant;
logic [Count-1:0] cycle;

localparam TotalWidth = DataWidth + AddrWidth + SelWidth + 3;
logic [TotalWidth-1:0] data[0:Count-1];

for(genvar i = 0; i < Count; i += 1) begin
  assign cycle[i] = leaders[i].cycle;
  assign data[i] = { leaders[i].cycle, leaders[i].strobe, leaders[i].write_enable, leaders[i].select, leaders[i].addr, leaders[i].write_data };
end

priority_arbiter
#(
  .Count(Count)
) arbiter0
(
  .clk,
  .reset_n,

  .requests(cycle),
  .grant
);

for(genvar i = 0; i < Count; i += 1) begin
  assign leaders[i].read_data = follower.read_data;
  assign leaders[i].ack = follower.ack;
  assign leaders[i].error = follower.error;
  assign leaders[i].stall = grant[i] == '0 ? 1'b1 : follower.stall;
end

onehot_mux
#(
  .Count(Count),
  .Width(TotalWidth)
) mux0
(
  .select(grant),
  .words_in(data),
  .word_out({ follower.cycle, follower.strobe, follower.write_enable, follower.select, follower.addr, follower.write_data })
);

endmodule
