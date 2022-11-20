`default_nettype none

/* verilator lint_off UNUSED */

//TODO Handle wb_err_i
// Instruction Fetch Unit
module riscv_ifu
(
  input wire logic clk_i,
  input wire logic reset_ni,

  // New PC (for jumps and branches)
  // This will invalidate any currently processing instructions
  input wire logic pc_valid_i,
  input wire logic [29:0] pc_i,

  // Interface to IDU
  input wire logic instr_ready_i, //TODO rename to ready_i ?
  output logic instr_valid_o, //TODO rename to valid_o ?
  output logic [31:0] instr_o,
  output logic [29:0] pc_o,

  // Master port
  input wire logic wb_ack_i,
  input wire logic wb_stall_i,
  input wire logic wb_err_i,
  input wire logic [31:0] wb_data_i,
  output logic [31:0] wb_data_o,
  output logic [29:0] wb_addr_o,
  output logic [3:0] wb_sel_o,
  output logic wb_cyc_o,
  output logic wb_stb_o,
  output logic wb_we_o
);

logic [29:0] pc_q;
logic [31:0] instr_q;
logic instr_valid_q;
logic cyc_q;
logic stb_q;
logic invalid_q; // Skip next ack

assign wb_sel_o = '0;
assign wb_data_o = '0;
assign wb_we_o = '0;

assign instr_o = instr_q;
assign instr_valid_o = instr_valid_q;
assign wb_cyc_o = cyc_q;
assign wb_stb_o = stb_q;
assign wb_addr_o = pc_q;

initial pc_q = '0;
initial instr_valid_q = '0;
initial cyc_q = '0;
initial stb_q = '0;
initial invalid_q = '0;

always_ff @(posedge clk_i) begin
  if((!reset_ni) || (!cyc_q) ) begin
    invalid_q <= '0;
  end else if(pc_valid_i) begin
    invalid_q <= '1;
  end
end

always_ff @(posedge clk_i) begin
  if((!reset_ni) || (cyc_q && wb_ack_i)) begin
    cyc_q <= '0;
    stb_q <= '0;
  end else if(!cyc_q && (!instr_valid_o)) begin
    cyc_q <= '1;
    stb_q <= '1;
  end else if(cyc_q) begin
    cyc_q <= '1;
    if(!wb_stall_i) begin
      stb_q <= '0;
    end
  end
end

always_ff @(posedge clk_i) begin
  if(wb_cyc_o && wb_ack_i) begin
    instr_q <= wb_data_i;
    pc_o <= pc_q;
  end
end

always_ff @(posedge clk_i) begin
  if(pc_valid_i) begin
    pc_q <= pc_i;
  end else if(instr_valid_q && instr_ready_i) begin
    pc_q <= pc_q + 1'b1;
  end
end

always_ff @(posedge clk_i) begin
  if((!reset_ni) || pc_valid_i) begin
    instr_valid_q <= '0;
  end else if(wb_cyc_o && wb_ack_i && !invalid_q) begin
    instr_valid_q <= '1;
  end else if(instr_ready_i) begin
    instr_valid_q <= '0;
  end
end

endmodule
