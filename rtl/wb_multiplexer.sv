`default_nettype none

module wb_multiplexer
#(
  parameter Count = 0,
  parameter MaskWidth = 0,

  parameter DataWidth = 32,
  parameter AddrWidth = 32,

  localparam SelWidth = DataWidth / 8,
  localparam TagWidth = $clog2(Count)
)
(
  input wire logic clk,
  input wire logic reset_n,

  // Master
  output logic [DataWidth-1:0] m_data_s,
  output logic m_ack,
  output logic m_stall,
  output logic m_err,

  input wire logic [DataWidth-1:0] m_data_m,
  input wire logic [AddrWidth-1:0] m_addr,
  input wire logic [SelWidth-1:0] m_sel,
  input wire logic m_cyc,
  input wire logic m_stb,
  input wire logic m_we,

  // Slaves
  input wire logic [DataWidth-1:0] s_data_s [Count],
  input wire logic s_ack [Count],
  input wire logic s_stall [Count],
  input wire logic s_err [Count],

  output wire logic [DataWidth-1:0] s_data_m [Count],
  output wire logic [AddrWidth-1:0] s_addr [Count],
  output wire logic [SelWidth-1:0] s_sel [Count],
  output wire logic s_cyc [Count],
  output wire logic s_stb [Count],
  output wire logic s_we [Count]
);

logic [AddrWidth-1:0] addr_masked;
logic [TagWidth-1:0] tag;

logic [AddrWidth-1:0] addr;
logic [AddrWidth-1:0] addr_reg;

always_comb begin
  addr = m_stb ? m_addr : addr_reg;
end

always_ff @(posedge clk) begin
  addr_reg <= addr;
end

bus_decoder
#(
  .MaskWidth(MaskWidth),
  .TagWidth(TagWidth),
  .AddrWidth(AddrWidth)
) decoder0
(
  .addr(addr),
  .addr_masked,
  .tag
);

always_comb begin
  m_data_s = s_data_s[tag];
  m_ack = s_ack[tag];
  m_stall = s_stall[tag];
  m_err = s_err[tag];
end

for(genvar i = 0; i < Count; i += 1) begin
  assign s_we[i] = m_we;
  assign s_addr[i] = addr_masked;
  assign s_data_m[i] = m_data_m;
  assign s_sel[i] = m_sel;
  assign s_cyc[i] = tag == i ? m_cyc : '0;
  assign s_stb[i] = tag == i ? m_stb : '0;
  assign s_we[i] = m_we;
end

endmodule
