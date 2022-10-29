`default_nettype none

interface bus
(
);

logic [31:0] addr;
logic [31:0] write_data;
logic [31:0] read_data;
logic [3:0] byte_enable;
logic read_data_valid;
logic read_req;
logic write_req;

modport leader
(
  output addr,
  output write_data,
  output byte_enable,
  output read_req,
  output write_req,
  input read_data,
  input read_data_valid
);

modport follower
(
  input addr,
  input write_data,
  input byte_enable,
  input read_req,
  input write_req,
  output read_data,
  output read_data_valid
);

endinterface
