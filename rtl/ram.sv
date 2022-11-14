`default_nettype none

/* verilator lint_off UNUSED */

module ram
#(
  parameter Depth = 0,

  localparam DataWidth = 32,
  localparam AddrWidth = $clog2(Depth),
  localparam SelWidth = DataWidth / 8
)
(
  input wire logic clk,

  output logic [DataWidth-1:0] bus_data_s,
  output logic bus_ack,
  output logic bus_stall,
  output logic bus_err,

  input wire logic [DataWidth-1:0] bus_data_m,
  input wire logic [AddrWidth-1:0] bus_addr,
  input wire logic [SelWidth-1:0] bus_sel,
  input wire logic bus_cyc,
  input wire logic bus_stb,
  input wire logic bus_we
);

logic [DataWidth-1:0] mem [0:Depth-1];

initial begin
  bus_ack = '0;
end

assign bus_err = '0;
assign bus_stall = '0;

always_ff @(posedge clk) begin
  for(integer i = 0; i < SelWidth; i += 1) begin
    if(bus_stb & bus_we & bus_sel[i]) begin
      mem[bus_addr][i * 8 +: 8] <= bus_data_m[i * 8 +: 8];
    end
  end

  // Not strictly needed, but it cleans up the trace a bit for now
  if(bus_stb) begin
    bus_data_s <= mem[bus_addr];
  end else begin
    bus_data_s <= '0;
  end

  bus_ack <= bus_stb;
end

endmodule
