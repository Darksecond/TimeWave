`default_nettype none

module led_interface_top
(
  input wire logic clk,
  input wire logic reset_n,

  output logic [3:0] leds
);

localparam DataWidth = 32;
localparam AddrWidth = 30;
localparam SelWidth = DataWidth / 8;

// Master
logic [DataWidth-1:0] m_data_s;
logic m_ack;
logic m_stall;
logic m_err;
logic [DataWidth-1:0] m_data_m;
logic [AddrWidth-1:0] m_addr;
logic [SelWidth-1:0] m_sel;
logic m_cyc;
logic m_stb;
logic m_we;

// Led
logic [DataWidth-1:0] led_data_s;
logic led_ack;
logic led_stall;
logic led_err;
logic [DataWidth-1:0] led_data_m;
logic [AddrWidth-1:0] led_addr;
logic [SelWidth-1:0] led_sel;
logic led_cyc;
logic led_stb;
logic led_we;

// Rom
logic [DataWidth-1:0] rom_data_s;
logic rom_ack;
logic rom_stall;
logic rom_err;
logic [DataWidth-1:0] rom_data_m;
logic [AddrWidth-1:0] rom_addr;
logic [SelWidth-1:0] rom_sel;
logic rom_cyc;
logic rom_stb;
logic rom_we;

wb_multiplexer
#(
  .Count(2),
  .MaskWidth(4)
) wbmux0
(
  .clk,
  .reset_n,

  .m_data_s(m_data_s),
  .m_ack(m_ack),
  .m_stall(m_stall),
  .m_err(m_err),
  .m_data_m(m_data_m),
  .m_addr(m_addr),
  .m_sel(m_sel),
  .m_cyc(m_cyc),
  .m_stb(m_stb),
  .m_we(m_we),

  .s_data_s('{rom_data_s, led_data_s}),
  .s_ack('{rom_ack, led_ack}),
  .s_stall('{rom_stall, led_stall}),
  .s_err('{rom_err, led_err}),
  .s_data_m('{rom_data_m, led_data_m}),
  .s_addr('{rom_addr, led_addr}),
  .s_sel('{rom_sel, led_sel}),
  .s_cyc('{rom_cyc, led_cyc}),
  .s_stb('{rom_stb, led_stb}),
  .s_we('{rom_we, led_we})
);

led_interface led0
(
  .clk,
  .reset_n,

  .bus_data_s(led_data_s),
  .bus_ack(led_ack),
  .bus_stall(led_stall),
  .bus_err(led_err),
  .bus_data_m(led_data_m),
  .bus_addr(led_addr),
  .bus_sel(led_sel),
  .bus_cyc(led_cyc),
  .bus_stb(led_stb),
  .bus_we(led_we),

  .leds
);

rom
#(
  .Contents("led.mem"),
  .Depth(4096) //16 Kilobytes
) rom0
(
  .clk,

  .bus_data_s(rom_data_s),
  .bus_ack(rom_ack),
  .bus_stall(rom_stall),
  .bus_err(rom_err),
  .bus_data_m(rom_data_m),
  .bus_addr(rom_addr),
  .bus_sel(rom_sel),
  .bus_cyc(rom_cyc),
  .bus_stb(rom_stb),
  .bus_we(rom_we)
);

cpu cpu0
(
  .clk,
  .reset_n,

  .m_instr_data_s(m_data_s),
  .m_instr_ack(m_ack),
  .m_instr_stall(m_stall),
  .m_instr_err(m_err),
  .m_instr_data_m(m_data_m),
  .m_instr_addr(m_addr),
  .m_instr_sel(m_sel),
  .m_instr_cyc(m_cyc),
  .m_instr_stb(m_stb),
  .m_instr_we(m_we)
);

endmodule
