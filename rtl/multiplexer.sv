`default_nettype none

module multiplexer
#(
  parameter SelectBits = 0,
  parameter DataWidth = 0,
  parameter Count = 0
)
(
  input wire logic [SelectBits-1:0] select,
  input wire logic [DataWidth-1:0] data_in [0:Count-1],
  output logic [DataWidth-1:0] data_out
);

assign data_out = data_in[select];

endmodule
