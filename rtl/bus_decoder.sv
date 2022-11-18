`default_nettype none

/* verilator lint_off UNUSED */

module bus_decoder
#(
  parameter MaskWidth = 0,
  parameter TagWidth = 0,
  parameter AddrWidth = 30,

  localparam DataWidth = AddrWidth - MaskWidth
)
(
  input wire logic [AddrWidth-1:0] addr_i,
  output logic [AddrWidth-1:0] addr_masked_o,
  output logic [TagWidth-1:0] tag_o
);

assign tag_o = addr_i[DataWidth + TagWidth - 1:DataWidth];
assign addr_masked_o = { {MaskWidth{1'b0}}, addr_i[DataWidth-1:0] };

endmodule
