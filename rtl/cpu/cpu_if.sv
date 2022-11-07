`default_nettype none

// CPU Instruction Fetch
module cpu_if
#(
  localparam WbDataWidth = 32,
  localparam WbAddrWidth = 30,
  localparam WbSelWidth = WbDataWidth / 8
)
(
  input wire logic clk,
  input wire logic reset_n,

  // 1c Pulse
  input wire logic pc_valid,
  input wire logic [29:0] pc,

  // 1c Pulse
  output logic instr_valid,
  output logic [WbDataWidth-1:0] instr,

  // Master port
  input wire logic [WbDataWidth-1:0] bus_data_s,
  input wire logic bus_ack,
  input wire logic bus_stall,
  input wire logic bus_err,
  output logic [WbDataWidth-1:0] bus_data_m,
  output logic [WbAddrWidth-1:0] bus_addr,
  output logic [WbSelWidth-1:0] bus_sel,
  output logic bus_cyc,
  output logic bus_stb,
  output logic bus_we
);

assign bus_we = '0;
assign bus_sel = '0;
assign bus_data_m = '0;

logic cyc;

pulse_latch cyc0
(
  .clk,
  .pulse_i(pc_valid),
  .clear_i(bus_ack),
  .level_o(cyc)
);

always_comb begin

  bus_addr = pc;
  instr_valid = bus_ack;
  instr = bus_data_s;
  bus_stb = pc_valid;
  bus_cyc = pc_valid || cyc;
end

endmodule
