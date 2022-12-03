`default_nettype none

module wb_arbiter_tb
#(
  parameter DataWidth = 32,
  parameter AddrWidth = 30,
  parameter Count = 0,

  localparam SelWidth = DataWidth / 8
)
(
  input wire logic clk_i,

  // Slaves
  input wire logic [DataWidth-1:0] wb_m_data_o [Count],
  input wire logic wb_m_ack_o [Count],
  input wire logic wb_m_stall_o [Count],
  input wire logic wb_m_err_o [Count],

  input wire logic [DataWidth-1:0] wb_m_data_i [Count],
  input wire logic [AddrWidth-1:0] wb_m_addr_i [Count],
  input wire logic [SelWidth-1:0] wb_m_sel_i [Count],
  input wire logic wb_m_cyc_i [Count],
  input wire logic wb_m_stb_i [Count],
  input wire logic wb_m_we_i [Count],

  // Master
  input wire logic [DataWidth-1:0] wb_s_data_i,
  input wire logic wb_s_ack_i,
  input wire logic wb_s_stall_i,
  input wire logic wb_s_err_i,

  input wire logic [DataWidth-1:0] wb_s_data_o,
  input wire logic [AddrWidth-1:0] wb_s_addr_o,
  input wire logic [SelWidth-1:0] wb_s_sel_o,
  input wire logic wb_s_cyc_o,
  input wire logic wb_s_stb_o,
  input wire logic wb_s_we_o,

  input wire logic [Count-1:0] grant_d,
  input wire logic [Count-1:0] grant_q,
  input wire logic [Count-1:0] cycle
);

logic past_valid;

initial past_valid = 1'b0;

always_ff @(posedge clk_i) past_valid <= 1'b1;

wb_master_tb
#(
  .DataWidth(DataWidth),
  .AddrWidth(AddrWidth)
) master0
(
  .clk_i,

  .wb_data_i(wb_s_data_i),
  .wb_ack_i(wb_s_ack_i),
  .wb_stall_i(wb_s_stall_i),
  .wb_err_i(wb_s_err_i),

  .wb_data_o(wb_s_data_o),
  .wb_addr_o(wb_s_addr_o),
  .wb_sel_o(wb_s_sel_o),
  .wb_cyc_o(wb_s_cyc_o),
  .wb_stb_o(wb_s_stb_o),
  .wb_we_o(wb_s_we_o)
);

for(genvar i=0;i<Count;i+=1) begin
  wb_slave_tb
  #(
    .DataWidth(DataWidth),
    .AddrWidth(AddrWidth)
  ) slave
  (
  .clk_i,

  .wb_data_o(wb_m_data_o[i]),
  .wb_ack_o(wb_m_ack_o[i]),
  .wb_stall_o(wb_m_stall_o[i]),
  .wb_err_o(wb_m_err_o[i]),

  .wb_data_i(wb_m_data_i[i]),
  .wb_addr_i(wb_m_addr_i[i]),
  .wb_sel_i(wb_m_sel_i[i]),
  .wb_cyc_i(wb_m_cyc_i[i]),
  .wb_stb_i(wb_m_stb_i[i]),
  .wb_we_i(wb_m_we_i[i])
  );

  always_ff @(posedge clk_i) begin
    if(!grant_q[i] && wb_m_cyc_i[i]) begin
      assume(wb_m_stb_i[i]);
    end
  end
end

always_comb if(wb_s_cyc_o) assert(|wb_m_cyc_i);

always_ff @(posedge clk_i) begin
  cover(past_valid && $fell(wb_s_cyc_o));
end

endmodule
