`default_nettype none

module cpu
#(
  localparam WbDataWidth = 32,
  localparam WbAddrWidth = 30,
  localparam WbSelWidth = WbDataWidth / 8
)
(
  input wire logic clk,
  input wire logic reset_n,

  // Instruction port (Master)
  input wire logic [WbDataWidth-1:0] m_instr_data_s,
  input wire logic m_instr_ack,
  input wire logic m_instr_stall,
  input wire logic m_instr_err,
  output logic [WbDataWidth-1:0] m_instr_data_m,
  output logic [WbAddrWidth-1:0] m_instr_addr,
  output logic [WbSelWidth-1:0] m_instr_sel,
  output logic m_instr_cyc,
  output logic m_instr_stb,
  output logic m_instr_we
);

logic if_ready, if_enable;
logic [29:0] pc;

logic [31:0] if_instr, instr;
logic [4:0] rs1, rs2;
logic [31:0] rs1_data, rs2_data;

initial begin
  pc = 30'h00000000;
end

always_ff @(posedge clk) begin
  if(if_ready) begin
    instr <= if_instr;
  end
end

cpu_regfile reg0
(
  .clk,
  .reset_n,

  .read0_addr_i(rs1),
  .read0_data_o(rs1_data),
  .read1_addr_i(rs2),
  .read1_data_o(rs2_data)
);

cpu_execute cpu_execute0
(
  .clk,
  .reset_n,

  .instr_i(instr),
  .rs1_data_i(rs1_data),
  .rs2_data_i(rs2_data)
);

cpu_decode cpu_decode0
(
  .clk,
  .reset_n,

  .instr_i(instr),
  .rs1_o(rs1),
  .rs2_o(rs2)
);

cpu_control cpu_control0
(
  .clk,
  .reset_n,

  .if_ready,
  .if_enable
);

cpu_if cpu_if0
(
  .clk,
  .reset_n,

  .instr_valid(if_ready),
  .instr(if_instr),
  .pc_valid(if_enable),
  .pc,

  .bus_data_s(m_instr_data_s),
  .bus_ack(m_instr_ack),
  .bus_stall(m_instr_stall),
  .bus_err(m_instr_err),
  .bus_data_m(m_instr_data_m),
  .bus_addr(m_instr_addr),
  .bus_sel(m_instr_sel),
  .bus_cyc(m_instr_cyc),
  .bus_stb(m_instr_stb),
  .bus_we(m_instr_we)
);

endmodule
