`default_nettype none

module bus_decoder
#(
  parameter MaskWidth = 0,
  parameter TagWidth = 0,
  parameter AddrWidth = 32,
  localparam DataWidth = AddrWidth - MaskWidth
)
(
  input wire logic [AddrWidth-1:0] addr,
  output logic [AddrWidth-1:0] addr_masked,
  output logic [TagWidth-1:0] tag
);

logic [MaskWidth-1:0] mask = '0;
assign tag = addr[DataWidth + TagWidth - 1:DataWidth];
assign addr_masked = { mask, addr[DataWidth-1:0] };

endmodule
