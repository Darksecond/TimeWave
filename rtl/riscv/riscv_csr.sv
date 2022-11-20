`default_nettype none

/* verilator lint_off UNUSED */

module riscv_csr
(
  input wire logic clk_i,
  input wire logic reset_ni,

  input wire logic [11:0] csr_i,

  output logic [31:0] data_o
);

logic [63:0] cycle_q;

initial cycle_q = '0;

always_ff @(posedge clk_i) begin
  if(!reset_ni) begin
    cycle_q <= 64'b0;
  end else begin
    cycle_q <= cycle_q + 64'b1;
  end
end

always_comb begin
  case(csr_i)
    12'hC00: data_o = cycle_q[31:0];
    12'hC80: data_o = cycle_q[63:32];
    default: data_o = '0;
  endcase
end

endmodule
