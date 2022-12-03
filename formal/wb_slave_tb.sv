`default_nettype none

module wb_slave_tb
#(
  parameter DataWidth = 32,
  parameter AddrWidth = 30,

  localparam SelWidth = DataWidth / 8
)
(
  input wire logic clk_i,

  input wire logic [DataWidth-1:0] wb_data_o,
  input wire logic wb_ack_o,
  input wire logic wb_stall_o,
  input wire logic wb_err_o,

  input wire logic [DataWidth-1:0] wb_data_i,
  input wire logic [AddrWidth-1:0] wb_addr_i,
  input wire logic [SelWidth-1:0] wb_sel_i,
  input wire logic wb_cyc_i,
  input wire logic wb_stb_i,
  input wire logic wb_we_i
);

logic past_valid;

initial past_valid = 1'b0;

initial assume(!wb_cyc_i);
initial assume(!wb_stb_i);

initial assert(!wb_ack_o);
initial assert(!wb_err_o);

always_ff @(posedge clk_i) past_valid <= 1'b1;

// STB can only be high if CYC is high
always_comb if(wb_stb_i) assume(wb_cyc_i);

// Write requests must have _some_ bytes selected
always_comb if(wb_stb_i && wb_we_i) assume(|wb_sel_i);

// Only ack or err can be high, not both
always_comb assert((!wb_ack_o) || (!wb_err_o));

// Request stays on the bus on a stall
always_ff @(posedge clk_i) begin
  if(past_valid && wb_cyc_i && $past(wb_stb_i && wb_stall_o)) begin
    assume(wb_stb_i);
    assume($stable(wb_we_i));
    assume($stable(wb_sel_i));
    assume($stable(wb_addr_i));
    if(wb_we_i) assume($stable(wb_data_i));
  end
end

endmodule
