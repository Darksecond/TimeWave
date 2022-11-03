`default_nettype none

interface wb_bus32
(
);

localparam DataWidth = 32;
localparam AddrWidth = 32;
localparam SelWidth = DataWidth/8;

logic [DataWidth-1:0] data_m;
logic [DataWidth-1:0] data_s;
logic [AddrWidth-1:0] addr;
logic [SelWidth-1:0] sel;

logic ack;
logic cyc;
logic stall;
logic err;
logic stb;
logic we;

modport master
(
  output data_m,
  output addr,
  output sel,
  output cyc,
  output stb,
  output we,

  input data_s,
  input ack,
  input stall,
  input err
);

modport slave
(
  input data_m,
  input addr,
  input sel,
  input cyc,
  input stb,
  input we,

  output data_s,
  output ack,
  output stall,
  output err
);

endinterface

module wb_bus32_master_unpack
#(
  parameter Count = 0,

  localparam DataWidth = 32,
  localparam AddrWidth = 32,
  localparam SelWidth = DataWidth/8
)
(
  wb_bus32.master masters [Count],

  output wire logic [DataWidth-1:0] data_s [Count],
  output wire logic ack [Count],
  output wire logic stall [Count],
  output wire logic err [Count],

  input logic [DataWidth-1:0] data_m [Count],
  input logic [AddrWidth-1:0] addr [Count],
  input logic [SelWidth-1:0] sel [Count],
  input logic cyc [Count],
  input logic stb [Count],
  input logic we [Count]
);

for(genvar i = 0; i < Count; i += 1) begin
  assign masters[i].data_m = data_m[i];
  assign masters[i].addr = addr[i];
  assign masters[i].sel = sel[i];
  assign masters[i].cyc = cyc[i];
  assign masters[i].stb = stb[i];
  assign masters[i].we = we[i];

  assign data_s[i] = masters[i].data_s;
  assign ack[i] = masters[i].ack;
  assign stall[i] = masters[i].stall;
  assign err[i] = masters[i].err;
end

endmodule

module wb_bus32_slave_unpack
#(
  parameter Count = 0,

  localparam DataWidth = 32,
  localparam AddrWidth = 32,
  localparam SelWidth = DataWidth/8
)
(
  wb_bus32.slave slaves [Count],

  input wire logic [DataWidth-1:0] data_s [Count],
  input wire logic ack [Count],
  input wire logic stall [Count],
  input wire logic err [Count],

  output logic [DataWidth-1:0] data_m [Count],
  output logic [AddrWidth-1:0] addr [Count],
  output logic [SelWidth-1:0] sel [Count],
  output logic cyc [Count],
  output logic stb [Count],
  output logic we [Count]
);

for(genvar i = 0; i < Count; i += 1) begin
  assign data_m[i] = slaves[i].data_m;
  assign addr[i] = slaves[i].addr;
  assign sel[i] = slaves[i].sel;
  assign cyc[i] = slaves[i].cyc;
  assign stb[i] = slaves[i].stb;
  assign we[i] = slaves[i].we;

  assign slaves[i].data_s = data_s[i];
  assign slaves[i].ack = ack[i];
  assign slaves[i].stall = stall[i];
  assign slaves[i].err = err[i];
end

endmodule
