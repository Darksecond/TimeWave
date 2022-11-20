`default_nettype none

/* verilator lint_off UNUSED */

module riscv_lsu
(
  input wire logic clk_i,
  input wire logic reset_ni,

  // EXU interface
  output logic ready_o,
  input wire logic valid_i,
  input wire logic [29:0] pc_i,

  input wire logic [4:0] rd_addr_i,
  input wire logic [31:0] rd_data_i,
  
  // mem signals
  input wire logic [31:0] mem_data_i,
  input wire logic mem_valid_i,
  input wire logic mem_we_i,
  input wire logic [2:0] mem_width_i,

  // WBU interface
  input wire logic ready_i,
  output logic valid_o,
  output logic [29:0] pc_o,

  output logic [4:0] rd_addr_o,
  output logic [31:0] rd_data_o,

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
  output logic wb_we_o,

  // Hazards
  output logic [4:0] hz_rd_addr_o
);

logic mem;
logic passthrough;

logic [3:0] wb_sel_d;
logic [31:0] wb_data_d;

logic [3:0] store_byte_select;
logic [31:0] store_byte_data;

logic [3:0] store_short_select;
logic [31:0] store_short_data;

logic [31:0] load_byte_data, load_short_data;
logic [31:0] rd_data_d;

logic [2:0] mem_width_q;
logic [1:0] mem_offset_q;

assign mem = ready_o && valid_i && mem_valid_i;
assign passthrough = ready_o && valid_i && !mem_valid_i;
assign ready_o = ready_i && ( ready_i || (!valid_o) ) && (!wb_cyc_o);

assign hz_rd_addr_o = valid_i ? rd_addr_i: '0;

initial wb_cyc_o = 1'b0;
initial wb_stb_o = 1'b0;
initial valid_o = 1'b0;

always_comb begin
  unique case(rd_data_i[1:0])
  2'b00: begin
    store_byte_select = 4'b0001;
    store_byte_data = {24'b0, mem_data_i[7:0]};
  end
  2'b01: begin
    store_byte_select = 4'b0010;
    store_byte_data = {16'b0, mem_data_i[7:0], 8'b0};
  end
  2'b10: begin
    store_byte_select = 4'b0100;
    store_byte_data = {8'b0, mem_data_i[7:0], 16'b0};
  end
  2'b11: begin
    store_byte_select = 4'b1000;
    store_byte_data = {mem_data_i[7:0], 24'b0};
  end
  default: begin
    store_byte_select = 4'b0000;
    store_byte_data = 32'b0;
  end
  endcase

  unique case(rd_data_i[1:0])
  2'b00: begin
    store_short_select = 4'b0011;
    store_short_data = {16'b0, mem_data_i[15:0]};
  end
  2'b10: begin
    store_short_select = 4'b1100;
    store_short_data = {mem_data_i[15:0], 16'b0};
  end
  default: begin
    store_short_select = 4'b0000;
    store_short_data = 32'b0;
  end
  endcase

  unique case(mem_width_q[1:0]) // MSB is for 'U', not used here
  2'b00: begin // 'B'
    wb_sel_d = store_byte_select;
    wb_data_d = store_byte_data;
  end
  2'b01: begin // 'H'
    wb_sel_d = store_short_select;
    wb_data_d = store_short_data;
  end
  2'b10: begin // 'W'
    wb_sel_d = 4'b1111;
    wb_data_d = mem_data_i;
  end
  default: begin
    wb_sel_d = 4'b0000;
    wb_data_d = 32'b0;
  end
  endcase
end

always_comb begin
  unique case(mem_offset_q)
  2'b00: begin
    load_byte_data = {24'b0, wb_data_i[7:0]};
  end
  2'b01: begin
    load_byte_data = {24'b0, wb_data_i[15:8]};
  end
  2'b10: begin
    load_byte_data = {24'b0, wb_data_i[23:16]};
  end
  2'b11: begin
    load_byte_data = {24'b0, wb_data_i[31:24]};
  end
  default: begin
    load_byte_data = 32'b0;
  end
  endcase

  unique case(mem_offset_q)
  2'b00: begin
    load_short_data = {16'b0, wb_data_i[15:0]};
  end
  2'b10: begin
    load_short_data = {16'b0, wb_data_i[31:16]};
  end
  default: begin
    load_short_data = 32'b0;
  end
  endcase

  unique case(mem_width_q) // MSB is for 'U', not used here
  3'b000: begin // 'B'
    rd_data_d = {{24{load_byte_data[7]}}, load_byte_data[7:0]};
  end
  3'b001: begin // 'H'
    rd_data_d = {{16{load_short_data[15]}}, load_short_data[15:0]};
  end
  3'b010: begin // 'W'
    rd_data_d = wb_data_i;
  end
  3'b100: begin // 'BU'
    rd_data_d = load_byte_data;
  end
  3'b101: begin // 'HU'
    rd_data_d = load_short_data;
  end
  default: begin
    rd_data_d = 32'b0;
  end
  endcase
end

always_ff @(posedge clk_i) begin
  if(valid_o && ready_i) begin
    valid_o <= '0;
  end

  if(wb_cyc_o && wb_stb_o && (!wb_stall_i)) begin
    wb_stb_o <= 1'b0;
  end

  if(!reset_ni) begin
    wb_cyc_o <= 1'b0;
    wb_stb_o <= 1'b0;
    valid_o <= 1'b0;
  end else if(passthrough) begin
    wb_cyc_o <= 1'b0;
    wb_stb_o <= 1'b0;
    valid_o <= valid_i;
  end else if(mem) begin
    valid_o <= 1'b0;
    wb_cyc_o <= 1'b1;
    wb_stb_o <= 1'b1;
  end

  if(wb_cyc_o && wb_ack_i) begin
    wb_cyc_o <= 1'b0;
    valid_o <= 1'b1;
  end
end

always_ff @(posedge clk_i) begin
  if(passthrough) begin
    pc_o <= pc_i;
    rd_addr_o <= rd_addr_i;
    rd_data_o <= rd_data_i;
  end else if(mem) begin
    pc_o <= pc_i;
    rd_addr_o <= rd_addr_i;

    mem_width_q <= mem_width_i;
    mem_offset_q <= rd_data_i[1:0];
    wb_we_o <= mem_we_i;
    wb_addr_o <= rd_data_i[31:2];
    wb_data_o <= wb_data_d;
    wb_sel_o <= wb_sel_d;
  end

  if(wb_cyc_o && wb_ack_i) begin
    rd_data_o <= rd_data_d;
  end
end

endmodule
