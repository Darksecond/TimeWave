`default_nettype none

module wb_master_tb
#(
  parameter DataWidth = 32,
  parameter AddrWidth = 30,

  localparam SelWidth = DataWidth / 8
)
(
  input wire logic clk_i,

  input wire logic [DataWidth-1:0] wb_data_i,
  input wire logic wb_ack_i,
  input wire logic wb_stall_i,
  input wire logic wb_err_i,

  input wire logic [DataWidth-1:0] wb_data_o,
  input wire logic [AddrWidth-1:0] wb_addr_o,
  input wire logic [SelWidth-1:0] wb_sel_o,
  input wire logic wb_cyc_o,
  input wire logic wb_stb_o,
  input wire logic wb_we_o
);

logic past_valid;

initial past_valid = 1'b0;

initial assert(!wb_cyc_o);
initial assert(!wb_stb_o);

initial assume(!wb_ack_i);
initial assume(!wb_err_i);

always_ff @(posedge clk_i) past_valid <= 1'b1;

// STB can only be high if CYC is high
always_comb if(wb_stb_o) assert(wb_cyc_o);

// Write requests must have _some_ bytes selected
always_comb if(wb_stb_o && wb_we_o) assert(|wb_sel_o);

// Only ack or err can be high, not both
always_comb assume((!wb_ack_i) || (!wb_err_i));

// Request stays on the bus on a stall
always_ff @(posedge clk_i) begin
  if(past_valid && wb_cyc_o && $past(wb_stb_o && wb_stall_i)) begin
    assert(wb_stb_o);
    assert($stable(wb_we_o));
    assert($stable(wb_sel_o));
    assert($stable(wb_addr_o));
    if(wb_we_o) assert($stable(wb_data_o));
  end
end

endmodule
