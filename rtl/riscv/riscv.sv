`default_nettype none

/* verilator lint_off UNUSED */

module riscv
(
  input wire logic clk_i,
  input wire logic reset_ni,

  // Instruction Port
  input wire logic wb_i_ack_i,
  input wire logic wb_i_stall_i,
  input wire logic wb_i_err_i,
  input wire logic [31:0] wb_i_data_i,
  output logic [31:0] wb_i_data_o,
  output logic [29:0] wb_i_addr_o,
  output logic [3:0] wb_i_sel_o,
  output logic wb_i_cyc_o,
  output logic wb_i_stb_o,
  output logic wb_i_we_o,

  // Data Port
  input wire logic wb_d_ack_i,
  input wire logic wb_d_stall_i,
  input wire logic wb_d_err_i,
  input wire logic [31:0] wb_d_data_i,
  output logic [31:0] wb_d_data_o,
  output logic [29:0] wb_d_addr_o,
  output logic [3:0] wb_d_sel_o,
  output logic wb_d_cyc_o,
  output logic wb_d_stb_o,
  output logic wb_d_we_o
);

logic if2id_ready;
logic if2id_valid;
logic [29:0] if2id_pc;
logic [31:0] if2id_instr;

logic [4:0] rf_rd0_addr;
logic [4:0] rf_rd1_addr;
logic [31:0] rf_rd0_data;
logic [31:0] rf_rd1_data;
logic rf_w_enable;
logic [4:0] rf_w_addr;
logic [31:0] rf_w_data;

logic [29:0] id2ex_pc;
logic [4:0] id2ex_rd_addr;
alu_cmd_t id2ex_alu_cmd;
logic [31:0] id2ex_alu_lhs;
logic [31:0] id2ex_alu_rhs;
logic [31:0] id2ex_branch_lhs;
logic [31:0] id2ex_branch_rhs;
branch_alu_cmd_t id2ex_branch_cmd;
logic id2ex_branch;
logic id2ex_ready;
logic id2ex_valid;
logic id2ex_mem_valid;
logic [31:0] id2ex_mem_data;
logic id2ex_mem_we;
logic [2:0] id2ex_mem_width;
logic id2ex_csr_valid;
logic [11:0] id2ex_csr;

logic ex2if_branch_valid;
logic [29:0] ex2if_branch_addr;

logic [4:0] hz_id_rs1, hz_id_rs2, hz_ex_rd, hz_ls_rd, hz_wb_rd;
logic hz_stall;

logic ex2ls_ready;
logic ex2ls_valid;
logic [29:0] ex2ls_pc;
logic [4:0] ex2ls_rd_addr;
logic [31:0] ex2ls_rd_data;
logic ex2ls_mem_valid;
logic [31:0] ex2ls_mem_data;
logic ex2ls_mem_we;
logic [2:0] ex2ls_mem_width;

logic ls2wb_ready;
logic ls2wb_valid;
logic [29:0] ls2wb_pc;
logic [4:0] ls2wb_rd_addr;
logic [31:0] ls2wb_rd_data;

riscv_regfile reg0
(
  .clk_i,

  .w_data_i(rf_w_data),
  .w_addr_i(rf_w_addr),
  .w_enable_i(rf_w_enable),

  // read port 0
  .rd0_addr_i(rf_rd0_addr),
  .rd0_data_o(rf_rd0_data),

  // read port 1
  .rd1_addr_i(rf_rd1_addr),
  .rd1_data_o(rf_rd1_data)
);

riscv_hazards hazard0
(
  .id_rs1_i(hz_id_rs1), // Decode
  .id_rs2_i(hz_id_rs2), // Decode

  .ex_rd_i(hz_ex_rd), // Execute
  .ls_rd_i(hz_ls_rd), // Load-Store
  .wb_rd_i(hz_wb_rd), // Writeback

  .stall_o(hz_stall)
);

riscv_ifu ifu0
(
  .clk_i,
  .reset_ni,

  // Tie ready to high
  .instr_ready_i(if2id_ready),
  .instr_valid_o(if2id_valid),
  .instr_o(if2id_instr),
  .pc_o(if2id_pc),

  .pc_i(ex2if_branch_addr),
  .pc_valid_i(ex2if_branch_valid),

  .wb_ack_i(wb_i_ack_i),
  .wb_stall_i(wb_i_stall_i),
  .wb_err_i(wb_i_err_i),
  .wb_data_i(wb_i_data_i),
  .wb_data_o(wb_i_data_o),
  .wb_addr_o(wb_i_addr_o),
  .wb_sel_o(wb_i_sel_o),
  .wb_cyc_o(wb_i_cyc_o),
  .wb_stb_o(wb_i_stb_o),
  .wb_we_o(wb_i_we_o)
);

riscv_idu idu0
(
  .clk_i,
  .reset_ni,

  .clear_i(ex2if_branch_valid),
  .stall_i(hz_stall),

  .ready_o(if2id_ready),
  .valid_i(if2id_valid),
  .instr_i(if2id_instr),
  .pc_i(if2id_pc),

  // EXU interface
  .ready_i(id2ex_ready),
  .valid_o(id2ex_valid),

  .pc_o(id2ex_pc),

  .rd_addr_o(id2ex_rd_addr),

  // alu
  .alu_cmd_o(id2ex_alu_cmd),
  .alu_lhs_o(id2ex_alu_lhs),
  .alu_rhs_o(id2ex_alu_rhs),

  // branch
  .branch_cmd_o(id2ex_branch_cmd),
  .branch_lhs_o(id2ex_branch_lhs),
  .branch_rhs_o(id2ex_branch_rhs),

  .branch_o(id2ex_branch), // Perform a jump or branch

  // mem
  .mem_valid_o(id2ex_mem_valid),
  .mem_data_o(id2ex_mem_data),
  .mem_we_o(id2ex_mem_we),
  .mem_width_o(id2ex_mem_width),

  // csr
  .csr_valid_o(id2ex_csr_valid),
  .csr_o(id2ex_csr),

  // hazards
  .hz_rs1_addr_o(hz_id_rs1),
  .hz_rs2_addr_o(hz_id_rs2),

  // Regfile interface
  .rf_rd0_addr_o(rf_rd0_addr),
  .rf_rd1_addr_o(rf_rd1_addr),
  .rf_rd0_data_i(rf_rd0_data),
  .rf_rd1_data_i(rf_rd1_data)
);

riscv_exu exu0
(
  .clk_i,
  .reset_ni,

  // IDU interface
  .ready_o(id2ex_ready),
  .valid_i(id2ex_valid),
  .pc_i(id2ex_pc),
  .rd_addr_i(id2ex_rd_addr),

  // alu
  .alu_cmd_i(id2ex_alu_cmd),
  .alu_lhs_i(id2ex_alu_lhs),
  .alu_rhs_i(id2ex_alu_rhs),

  // branch
  .branch_cmd_i(id2ex_branch_cmd),
  .branch_lhs_i(id2ex_branch_lhs),
  .branch_rhs_i(id2ex_branch_rhs),

  .branch_i(id2ex_branch),

  // mem
  .mem_valid_i(id2ex_mem_valid),
  .mem_data_i(id2ex_mem_data),
  .mem_we_i(id2ex_mem_we),
  .mem_width_i(id2ex_mem_width),

  // csr
  .csr_valid_i(id2ex_csr_valid),
  .csr_i(id2ex_csr),

  // MEM interface
  .ready_i(ex2ls_ready),
  .valid_o(ex2ls_valid),
  .pc_o(ex2ls_pc),

  .rd_addr_o(ex2ls_rd_addr),
  .rd_data_o(ex2ls_rd_data),

  // mem
  .mem_valid_o(ex2ls_mem_valid),
  .mem_data_o(ex2ls_mem_data),
  .mem_we_o(ex2ls_mem_we),
  .mem_width_o(ex2ls_mem_width),

  // Branch (-> IFU)
  .branch_valid_o(ex2if_branch_valid),
  .branch_addr_o(ex2if_branch_addr),

  // Hazards
  .hz_rd_addr_o(hz_ex_rd)
);

riscv_lsu lsu0
(
  .clk_i,
  .reset_ni,

  // EXU interface
  .ready_o(ex2ls_ready),
  .valid_i(ex2ls_valid),
  .pc_i(ex2ls_pc),

  .rd_addr_i(ex2ls_rd_addr),
  .rd_data_i(ex2ls_rd_data),

  // mem
  .mem_valid_i(ex2ls_mem_valid),
  .mem_data_i(ex2ls_mem_data),
  .mem_we_i(ex2ls_mem_we),
  .mem_width_i(ex2ls_mem_width),

  // WBU interface
  .ready_i(ls2wb_ready),
  .valid_o(ls2wb_valid),
  .pc_o(ls2wb_pc),

  .rd_addr_o(ls2wb_rd_addr),
  .rd_data_o(ls2wb_rd_data),

  // Bus master
  .wb_ack_i(wb_d_ack_i),
  .wb_stall_i(wb_d_stall_i),
  .wb_err_i(wb_d_err_i),
  .wb_data_i(wb_d_data_i),
  .wb_data_o(wb_d_data_o),
  .wb_addr_o(wb_d_addr_o),
  .wb_sel_o(wb_d_sel_o),
  .wb_cyc_o(wb_d_cyc_o),
  .wb_stb_o(wb_d_stb_o),
  .wb_we_o(wb_d_we_o),

  // Hazards
  .hz_rd_addr_o(hz_ls_rd)
);

riscv_wbu wbu0
(
  .clk_i,
  .reset_ni,

  // MEM interface
  .ready_o(ls2wb_ready),
  .valid_i(ls2wb_valid),
  .pc_i(ls2wb_pc),

  .rd_addr_i(ls2wb_rd_addr),
  .rd_data_i(ls2wb_rd_data),

  // Regfile
  .rf_w_enable_o(rf_w_enable),
  .rf_w_addr_o(rf_w_addr),
  .rf_w_data_o(rf_w_data),

  // Hazards
  .hz_rd_addr_o(hz_wb_rd)
);

endmodule
