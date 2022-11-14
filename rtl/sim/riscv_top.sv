`default_nettype none

/* verilator lint_off UNUSED */

module riscv_top
(
  input wire logic clk_i,
  input wire logic reset_ni,
  output logic [3:0] leds_o
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

assign leds_o = '0;

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

  .wb_d_data_i(ram_data_s),
  .wb_d_ack_i(ram_ack),
  .wb_d_stall_i(ram_stall),
  .wb_d_err_i(ram_err),
  .wb_d_data_o(ram_data_m),
  .wb_d_addr_o(ram_addr),
  .wb_d_sel_o(ram_sel),
  .wb_d_cyc_o(ram_cyc),
  .wb_d_stb_o(ram_stb),
  .wb_d_we_o(ram_we)
);

endmodule
