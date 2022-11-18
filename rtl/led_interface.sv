`default_nettype none

/* verilator lint_off UNUSED */

module led_interface
#(
  localparam DataWidth = 32,
  localparam AddrWidth = 30,
  localparam SelWidth = DataWidth / 8
)
(
  input wire logic clk_i,
  input wire logic reset_ni,

  output logic [DataWidth-1:0] wb_data_o,
  output logic wb_ack_o,
  output logic wb_stall_o,
  output logic wb_err_o,

  input wire logic [DataWidth-1:0] wb_data_i,
  input wire logic [AddrWidth-1:0] wb_addr_i,
  input wire logic [SelWidth-1:0] wb_sel_i,
  input wire logic wb_cyc_i,
  input wire logic wb_stb_i,
  input wire logic wb_we_i,

  output logic [3:0] leds_o
);

logic [3:0] leds_d;

initial begin
  leds_o = '0;
  wb_ack_o = '0;
end

always_comb begin
  wb_data_o = {28'h0, leds_o};
  wb_stall_o = '0;
  wb_err_o = '0;

  leds_d = leds_o;

  if (wb_stb_i && wb_we_i && wb_sel_i[0]) begin
    leds_d = wb_data_i[3:0];
  end
end

always_ff @(posedge clk_i) begin
  if(!reset_ni) begin
    leds_o <= '0;
    wb_ack_o <= '0;
  end else begin
    leds_o <= leds_d;
    wb_ack_o <= wb_stb_i;
  end
end

endmodule
