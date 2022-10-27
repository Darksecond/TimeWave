`default_nettype none

module rom
#(
  parameter Contents = "",
  parameter AddrWidth = 0,
  parameter DataWidth = 0,
  parameter Depth = 0
)
(
  input wire logic clk,

  input wire logic [AddrWidth-1:0] addr,

  input wire logic read_req,
  output logic [DataWidth-1:0] read_data,
  output logic read_data_valid
);

logic [DataWidth-1:0] mem [0:Depth-1];

initial begin
  $readmemh(Contents, mem);
end

always_ff @(posedge clk) begin
  read_data <= mem[addr];
  read_data_valid <= read_req;
end

endmodule
