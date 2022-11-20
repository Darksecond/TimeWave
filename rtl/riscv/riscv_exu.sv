`default_nettype none

/* verilator lint_off UNUSED */

module riscv_exu
(
  input wire logic clk_i,
  input wire logic reset_ni,

  // IDU interface
  output logic ready_o,
  input wire logic valid_i,
  input wire logic [29:0] pc_i,
  input wire logic [4:0] rd_addr_i,

  // alu
  input wire alu_cmd_t alu_cmd_i,
  input wire logic [31:0] alu_lhs_i,
  input wire logic [31:0] alu_rhs_i,

  // branch
  input wire branch_alu_cmd_t branch_cmd_i,
  input wire logic [31:0] branch_lhs_i,
  input wire logic [31:0] branch_rhs_i,

  input wire logic branch_i,

  // mem signals
  input wire logic [31:0] mem_data_i,
  input wire logic mem_valid_i,
  input wire logic mem_we_i,
  input wire logic [2:0] mem_width_i,

  //csr signals
  input wire logic csr_valid_i,
  input wire logic [11:0] csr_i,

  // MEM interface
  input wire logic ready_i,
  output logic valid_o,
  output logic [29:0] pc_o,

  output logic [4:0] rd_addr_o,
  output logic [31:0] rd_data_o,

  // mem signals
  output logic [31:0] mem_data_o,
  output logic mem_valid_o,
  output logic mem_we_o,
  output logic [2:0] mem_width_o,

  // Branch (-> IFU)
  output logic branch_valid_o,
  output logic [29:0] branch_addr_o,

  // Hazards
  output logic [4:0] hz_rd_addr_o
);

logic branch_res_d;
logic [29:0] branch_addr_d;

logic [31:0] alu_res_d;
logic branch_valid_d;

logic [4:0] rd_addr_d;
logic [31:0] rd_data_d;

logic [31:0] csr_d;

assign ready_o = ready_i;

assign hz_rd_addr_o = valid_i ? rd_addr_i: '0;

initial valid_o = '0;

riscv_csr csr0
(
  .clk_i,
  .reset_ni,
  .csr_i,
  .data_o(csr_d)
);

alu alu0
(
  .cmd_i(alu_cmd_i),
  .lhs_i(alu_lhs_i),
  .rhs_i(alu_rhs_i),
  .res_o(alu_res_d)
);

branch_alu cmp0
(
  .cmd_i(branch_cmd_i),
  .lhs_i(branch_lhs_i),
  .rhs_i(branch_rhs_i),
  .res_o(branch_res_d)
);

always_comb begin
  branch_valid_d = branch_res_d && branch_i && valid_i;
  branch_addr_d = alu_res_d[31:2];
  rd_addr_d = rd_addr_i;

  rd_data_d = branch_i ? ({pc_i, 2'b00} + 32'h4) : alu_res_d;
  rd_data_d = csr_valid_i ? csr_d : rd_data_d;
end

always_ff @(posedge clk_i) begin
  if(valid_o && ready_i) begin
    valid_o <= '0;
  end

  if(ready_o) begin
    valid_o <= valid_i;
  end

  if((!reset_ni)) begin
    valid_o <= '0;
  end
end

always_ff @(posedge clk_i) begin
  if(ready_o) begin
    pc_o <= pc_i;

    branch_valid_o <= branch_valid_d;
    branch_addr_o <= branch_addr_d;

    rd_addr_o <= rd_addr_d;
    rd_data_o <= rd_data_d;

    mem_data_o <= mem_data_i;
    mem_valid_o <= mem_valid_i;
    mem_we_o <= mem_we_i;
    mem_width_o <= mem_width_i;
  end
end

endmodule
