`default_nettype none

module wb_arbiter
#(
  parameter DataWidth = 32,
  parameter AddrWidth = 30,
  parameter Count = 0,

  localparam SelWidth = DataWidth / 8
)
(
  input wire logic clk_i,
  input wire logic reset_ni,

  // Masters
  output logic [DataWidth-1:0] wb_m_data_o [Count],
  output logic wb_m_ack_o [Count],
  output logic wb_m_stall_o [Count],
  output logic wb_m_err_o [Count],

  input wire logic [DataWidth-1:0] wb_m_data_i [Count],
  input wire logic [AddrWidth-1:0] wb_m_addr_i [Count],
  input wire logic [SelWidth-1:0] wb_m_sel_i [Count],
  input wire logic wb_m_cyc_i [Count],
  input wire logic wb_m_stb_i [Count],
  input wire logic wb_m_we_i [Count],

  // Slave
  input wire logic [DataWidth-1:0] wb_s_data_i,
  input wire logic wb_s_ack_i,
  input wire logic wb_s_stall_i,
  input wire logic wb_s_err_i,

  output logic [DataWidth-1:0] wb_s_data_o,
  output logic [AddrWidth-1:0] wb_s_addr_o,
  output logic [SelWidth-1:0] wb_s_sel_o,
  output logic wb_s_cyc_o,
  output logic wb_s_stb_o,
  output logic wb_s_we_o
);

logic [Count-1:0] grant;
logic [Count-1:0] cycle;

localparam TotalWidth = DataWidth + AddrWidth + SelWidth + 3;
logic [TotalWidth-1:0] data [Count];

for(genvar i = 0; i < Count; i += 1) begin
  assign cycle[i] = wb_m_cyc_i[i];
  assign data[i] = { wb_m_cyc_i[i], wb_m_stb_i[i], wb_m_we_i[i], wb_m_sel_i[i], wb_m_addr_i[i], wb_m_data_i[i] };
end

priority_arbiter
#(
  .Count(Count)
) arbiter0
(
  .clk_i,

  .requests_i(cycle),
  .grant_o(grant)
);

for(genvar i = 0; i < Count; i += 1) begin
  assign wb_m_data_o[i] = wb_s_data_i;
  assign wb_m_ack_o[i] = wb_s_ack_i;
  assign wb_m_err_o[i] = wb_s_err_i;
  assign wb_m_stall_o[i] = grant[i] == '0 ? 1'b1 : wb_s_stall_i;
end

onehot_mux
#(
  .Count(Count),
  .Width(TotalWidth)
) mux0
(
  .select_i(grant),
  .words_i(data),
  .word_o({ wb_s_cyc_o, wb_s_stb_o, wb_s_we_o, wb_s_sel_o, wb_s_addr_o, wb_s_data_o })
);

// Formal
`ifdef FORMAL
  wb_arbiter_tb
  #(
    .DataWidth(DataWidth),
    .AddrWidth(AddrWidth),
    .Count(Count)
  ) tb0(.*);
`endif

endmodule
