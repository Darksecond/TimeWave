`default_nettype none

module system_bus
#(
  parameter Followers = 0,
  localparam FollowerBits = $clog2(Followers)
)
(
  input wire logic clk,
  input wire logic reset_n,
  bus.follower leader,
  bus.leader followers[0:Followers-1]
);

logic [3:0] tag;
logic [31:0] addr_masked;
logic [FollowerBits-1:0] select;
logic [Followers-1:0] requests;
logic [31:0] read_data [0:Followers-1];

logic [31:0] leader_addr;
logic [31:0] leader_write_data;
logic [0:0] leader_write;
logic [3:0] leader_byte_enable;

logic leader_empty;
logic leader_read_enable;
logic leader_valid;

assign leader_read_enable = !leader_empty;

always_ff @(posedge clk) begin
  leader_valid <= !leader_empty;
end

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
  .addr(leader_addr),
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
  always_ff @(posedge clk) begin
    if (tag == i && leader_valid) begin
      followers[i].addr <= addr_masked;
      followers[i].read_req <= !leader_write;
      followers[i].write_req <= leader_write;
      followers[i].byte_enable <= leader_byte_enable;
      followers[i].write_data <= leader_write_data;
    end else begin
      followers[i].addr <= 0;
      followers[i].read_req <= 0;
      followers[i].write_req <= 0;
      followers[i].byte_enable <= 0;
      followers[i].write_data <= 0;
    end
  end
end

fifo
#(
  .Width(32),
  .DepthBits(5)
) leader_fifo_addr
(
  .clk(clk),
  .reset_n(reset_n),

  .write_enable(leader.read_req | leader.write_req),
  .write_data(leader.addr),

  .read_enable(leader_read_enable),
  .read_data(leader_addr),
  .empty(leader_empty)
);

fifo
#(
  .Width(1),
  .DepthBits(5)
) leader_fifo_write
(
  .clk(clk),
  .reset_n(reset_n),

  .write_enable(leader.read_req | leader.write_req),
  .write_data(leader.write_req),

  .read_enable(leader_read_enable),
  .read_data(leader_write)
);

fifo
#(
  .Width(32),
  .DepthBits(5)
) leader_fifo_write_data
(
  .clk(clk),
  .reset_n(reset_n),

  .write_enable(leader.read_req | leader.write_req),
  .write_data(leader.write_data),

  .read_enable(leader_read_enable),
  .read_data(leader_write_data)
);

fifo
#(
  .Width(4),
  .DepthBits(5)
) leader_fifo_byte_enable
(
  .clk(clk),
  .reset_n(reset_n),

  .write_enable(leader.read_req | leader.write_req),
  .write_data(leader.byte_enable),

  .read_enable(leader_read_enable),
  .read_data(leader_byte_enable)
);

endmodule
