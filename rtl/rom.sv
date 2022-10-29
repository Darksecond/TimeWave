`default_nettype none

module rom
#(
  parameter Contents = "",
  parameter Depth = 0
)
(
  input wire logic clk,

  bus.follower bus
);

logic [31:0] mem [0:Depth-1];

initial begin
  $readmemh(Contents, mem);
end

always_ff @(posedge clk) begin
  bus.read_data <= mem[bus.addr];
  bus.read_data_valid <= bus.read_req;
end

endmodule
