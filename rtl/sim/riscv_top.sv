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
  .wb_i_we_o(rom_we)
);

endmodule
