`default_nettype none

/* verilator lint_off UNUSED */

module riscv_top
(
  input wire logic clk_i,
  input wire logic reset_ni,
  output logic [3:0] leds_o,
  output logic tx_o
);

// Rom
logic [31:0] rom_data_s;
logic rom_ack;
logic rom_stall;
logic rom_err;
logic [31:0] rom_data_m;
logic [29:0] rom_addr;
logic [3:0] rom_sel;
logic rom_cyc;
logic rom_stb;
logic rom_we;

// Ram
logic [31:0] ram_data_s;
logic ram_ack;
logic ram_stall;
logic ram_err;
logic [31:0] ram_data_m;
logic [29:0] ram_addr;
logic [3:0] ram_sel;
logic ram_cyc;
logic ram_stb;
logic ram_we;

// Led
logic [31:0] led_data_s;
logic led_ack;
logic led_stall;
logic led_err;
logic [31:0] led_data_m;
logic [29:0] led_addr;
logic [3:0] led_sel;
logic led_cyc;
logic led_stb;
logic led_we;

// Uart (TX)
logic [31:0] uart_data_s;
logic uart_ack;
logic uart_stall;
logic uart_err;
logic [31:0] uart_data_m;
logic [29:0] uart_addr;
logic [3:0] uart_sel;
logic uart_cyc;
logic uart_stb;
logic uart_we;

// Mux
logic [31:0] mux_data_s;
logic mux_ack;
logic mux_stall;
logic mux_err;
logic [31:0] mux_data_m;
logic [29:0] mux_addr;
logic [3:0] mux_sel;
logic mux_cyc;
logic mux_stb;
logic mux_we;

wb_multiplexer
#(
  .Count(3),
  .MaskWidth(4)
) mux0
(
  .clk_i,
  .reset_ni,

  .wb_m_data_o(mux_data_s),
  .wb_m_ack_o(mux_ack),
  .wb_m_stall_o(mux_stall),
  .wb_m_err_o(mux_err),
  .wb_m_data_i(mux_data_m),
  .wb_m_addr_i(mux_addr),
  .wb_m_sel_i(mux_sel),
  .wb_m_cyc_i(mux_cyc),
  .wb_m_stb_i(mux_stb),
  .wb_m_we_i(mux_we),

  .wb_s_ack_i('{ram_ack, led_ack, uart_ack}),
  .wb_s_stall_i('{ram_stall, led_stall, uart_stall}),
  .wb_s_err_i('{ram_err, led_err, uart_err}),
  .wb_s_data_o('{ram_data_m, led_data_m, uart_data_m}),
  .wb_s_data_i('{ram_data_s, led_data_s, uart_data_s}),
  .wb_s_addr_o('{ram_addr, led_addr, uart_addr}),
  .wb_s_sel_o('{ram_sel, led_sel, uart_sel}),
  .wb_s_cyc_o('{ram_cyc, led_cyc, uart_cyc}),
  .wb_s_stb_o('{ram_stb, led_stb, uart_stb}),
  .wb_s_we_o('{ram_we, led_we, uart_we})
);

wb_uart_tx uart0
(
  .clk_i,
  .tx_o,

  .wb_data_o(uart_data_s),
  .wb_ack_o(uart_ack),
  .wb_stall_o(uart_stall),
  .wb_err_o(uart_err),
  .wb_data_i(uart_data_m),
  .wb_addr_i(uart_addr),
  .wb_sel_i(uart_sel),
  .wb_cyc_i(uart_cyc),
  .wb_stb_i(uart_stb),
  .wb_we_i(uart_we)
);

led_interface led0
(
  .clk_i,
  .reset_ni,
  .leds_o,

  .wb_data_o(led_data_s),
  .wb_ack_o(led_ack),
  .wb_stall_o(led_stall),
  .wb_err_o(led_err),
  .wb_data_i(led_data_m),
  .wb_addr_i(led_addr),
  .wb_sel_i(led_sel),
  .wb_cyc_i(led_cyc),
  .wb_stb_i(led_stb),
  .wb_we_i(led_we)
);

rom
#(
  .Contents("bootrom.mem"),
  .Depth(4096) //16 Kilobytes
) rom0
(
  .clk(clk_i),

  .bus_data_s(rom_data_s),
  .bus_ack(rom_ack),
  .bus_stall(rom_stall),
  .bus_err(rom_err),
  .bus_data_m(rom_data_m),
  .bus_addr(rom_addr[11:0]),
  .bus_sel(rom_sel),
  .bus_cyc(rom_cyc),
  .bus_stb(rom_stb),
  .bus_we(rom_we)
);

ram
#(
  .Depth(16384) // 64 Kilobytes
) ram0
(
  .clk(clk_i),

  .bus_data_s(ram_data_s),
  .bus_ack(ram_ack),
  .bus_stall(ram_stall),
  .bus_err(ram_err),
  .bus_data_m(ram_data_m),
  .bus_addr(ram_addr[13:0]),
  .bus_sel(ram_sel),
  .bus_cyc(ram_cyc),
  .bus_stb(ram_stb),
  .bus_we(ram_we)
);

riscv cpu0
(
  .clk_i,
  .reset_ni,

  .wb_i_data_i(rom_data_s),
  .wb_i_ack_i(rom_ack),
  .wb_i_stall_i(rom_stall),
  .wb_i_err_i(rom_err),
  .wb_i_data_o(rom_data_m),
  .wb_i_addr_o(rom_addr),
  .wb_i_sel_o(rom_sel),
  .wb_i_cyc_o(rom_cyc),
  .wb_i_stb_o(rom_stb),
  .wb_i_we_o(rom_we),

  .wb_d_data_i(mux_data_s),
  .wb_d_ack_i(mux_ack),
  .wb_d_stall_i(mux_stall),
  .wb_d_err_i(mux_err),
  .wb_d_data_o(mux_data_m),
  .wb_d_addr_o(mux_addr),
  .wb_d_sel_o(mux_sel),
  .wb_d_cyc_o(mux_cyc),
  .wb_d_stb_o(mux_stb),
  .wb_d_we_o(mux_we)
);

endmodule
