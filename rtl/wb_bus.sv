`default_nettype none

interface wb_bus
#(
  parameter DataWidth = 32,
  parameter AddrWidth = 32,

  localparam SelWidth = DataWidth/8
)
(
);

logic [DataWidth-1:0] write_data;
logic [DataWidth-1:0] read_data;
logic [AddrWidth-1:0] addr;
logic [SelWidth-1:0] select;

logic ack;
logic cycle;
logic stall;
logic error;
logic strobe;
logic write_enable;

modport leader
(
  output write_data,
  output addr,
  output select,
  output cycle,
  output strobe,
  output write_enable,

  input read_data,
  input ack,
  input stall,
  input error
);

modport follower
(
  input write_data,
  input addr,
  input select,
  input cycle,
  input strobe,
  input write_enable,

  output read_data,
  output ack,
  output stall,
  output error
);

endinterface
