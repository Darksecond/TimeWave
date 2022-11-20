`default_nettype none

/* verilator lint_off UNUSED */

module riscv_regfile
(
  input wire logic clk_i,

  // write port
  input wire logic [31:0] w_data_i,
  input wire logic [4:0] w_addr_i,
  input wire logic w_enable_i,

  // read port 0
  input wire logic [4:0] rd0_addr_i,
  output logic [31:0] rd0_data_o,

  // read port 1
  input wire logic [4:0] rd1_addr_i,
  output logic [31:0] rd1_data_o
);

logic [31:0] regs[32];

initial begin
  for(int i = 0; i < 32; i+= 1) begin
    regs[i] = 0;
  end
end

always_comb begin
  rd0_data_o = regs[rd0_addr_i];
  rd1_data_o = regs[rd1_addr_i];
end

always_ff @(posedge clk_i) begin
  if(w_enable_i && w_addr_i != '0) begin
    regs[w_addr_i] <= w_data_i;
  end
end

endmodule
