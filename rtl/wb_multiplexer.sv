`default_nettype none

/* verilator lint_off UNUSED */

module wb_multiplexer
#(
  parameter Count = 0,
  parameter MaskWidth = 0,

  parameter DataWidth = 32,
  parameter AddrWidth = 30,

  localparam SelWidth = DataWidth / 8,
  localparam TagWidth = $clog2(Count)
)
(
  input wire logic clk_i,
  input wire logic reset_ni,

  // Master
  output logic [DataWidth-1:0] wb_m_data_o,
  output logic wb_m_ack_o,
  output logic wb_m_stall_o,
  output logic wb_m_err_o,

  input wire logic [DataWidth-1:0] wb_m_data_i,
  input wire logic [AddrWidth-1:0] wb_m_addr_i,
  input wire logic [SelWidth-1:0] wb_m_sel_i,
  input wire logic wb_m_cyc_i,
  input wire logic wb_m_stb_i,
  input wire logic wb_m_we_i,

  // Slaves
  input wire logic [DataWidth-1:0] wb_s_data_i [Count],
  input wire logic wb_s_ack_i [Count],
  input wire logic wb_s_stall_i [Count],
  input wire logic wb_s_err_i [Count],

  output logic [DataWidth-1:0] wb_s_data_o [Count],
  output logic [AddrWidth-1:0] wb_s_addr_o [Count],
  output logic [SelWidth-1:0] wb_s_sel_o [Count],
  output logic wb_s_cyc_o [Count],
  output logic wb_s_stb_o [Count],
  output logic wb_s_we_o [Count]
);

logic [AddrWidth-1:0] addr_masked;
logic [TagWidth-1:0] tag;

logic [AddrWidth-1:0] addr_d;
logic [AddrWidth-1:0] addr_q;

always_comb begin
  addr_d = wb_m_stb_i ? wb_m_addr_i : addr_q;
end

always_ff @(posedge clk_i) begin
  addr_q <= addr_d;
end

bus_decoder
#(
  .MaskWidth(MaskWidth),
  .TagWidth(TagWidth),
  .AddrWidth(AddrWidth)
) decoder0
(
  .addr_i(addr_d),
  .addr_masked_o(addr_masked),
  .tag_o(tag)
);

always_comb begin
  wb_m_data_o = wb_s_data_i[tag];
  wb_m_ack_o = wb_s_ack_i[tag];
  wb_m_stall_o = wb_s_stall_i[tag];
  wb_m_err_o = wb_s_err_i[tag];
end

for(genvar i = 0; i < Count; i += 1) begin
  assign wb_s_we_o[i] = wb_m_we_i;
  assign wb_s_addr_o[i] = addr_masked;
  assign wb_s_data_o[i] = wb_m_data_i;
  assign wb_s_sel_o[i] = wb_m_sel_i;
  assign wb_s_cyc_o[i] = tag == i ? wb_m_cyc_i : '0; //TODO Add a 'slave_selected' signal to merge these two `tag == i`.
  assign wb_s_stb_o[i] = tag == i ? wb_m_stb_i : '0;
  assign wb_s_we_o[i] = wb_m_we_i;
end

endmodule
