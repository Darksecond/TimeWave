`default_nettype none

// CPU Instruction Fetch
module cpu_if
#(
  localparam DataWidth = 32,
  localparam AddrWidth = 32,
  localparam SelWidth = DataWidth / 8
)
(
  input wire logic clk,
  input wire logic reset_n,

  input wire logic pc_valid,
  input wire logic [AddrWidth-1:0] pc,
  output logic [DataWidth-1:0] instr,
  output logic instr_valid,

  // Master port
  input wire logic [DataWidth-1:0] bus_data_s,
  input wire logic bus_ack,
  input wire logic bus_stall,
  input wire logic bus_err,
  output logic [DataWidth-1:0] bus_data_m,
  output logic [AddrWidth-1:0] bus_addr,
  output logic [SelWidth-1:0] bus_sel,
  output logic bus_cyc,
  output logic bus_stb,
  output logic bus_we
);

assign bus_we = '0;
assign bus_sel = '0;
assign bus_data_m = '0;

logic cyc;

pulse_latch cyc0
(
  .clk,
  .pulse_i(pc_valid),
  .clear_i(bus_ack),
  .level_o(cyc)
);

always_comb begin

  bus_addr = pc;
  instr_valid = bus_ack;
  instr = bus_data_s;
  bus_stb = pc_valid;
  bus_cyc = pc_valid || cyc;
end

endmodule

module cpu_control
#(
)
(
  input wire logic clk,
  input wire logic reset_n,

  input wire logic if_ready,
  output logic if_enable
);

logic [1:0] state, state_next;

pulse_generator if_enable0
(
  .clk,
  .level_i(state == 2'h0),
  .posedge_o(if_enable)
);

always_comb begin
  state_next = state;

  case(state)
    2'h0: begin
      if(if_ready) state_next = 2'h1;
    end
    2'h1: begin
      state_next = 2'h0;
    end
  endcase
end

always_ff @(posedge clk) begin
  if(!reset_n) begin
    state <= '0;
  end else begin
    state <= state_next;
  end
end

endmodule

module pulse_generator
(
  input wire logic clk,
  input wire logic level_i,

  output logic posedge_o,
  output logic negedge_o,
  output logic anyedge_o
);

logic level_prev;

initial begin
  level_prev = '0;
end

always_ff @(posedge clk) begin
  level_prev <= level_i;
end

always_comb begin
  posedge_o = (level_i == '1) && (level_prev == '0);
  negedge_o = (level_i == '0) && (level_prev == '1);
  anyedge_o = posedge_o || negedge_o;
end

endmodule

module pulse_latch
(
  input wire logic clk,

  input wire logic pulse_i,
  input wire logic clear_i,

  output logic level_o
);

logic level;

initial begin
  level_o = '0;
end

always_ff @(posedge clk) begin
  if(pulse_i) begin
    level_o <= '1;
  end
  if(clear_i) begin
    level_o <= '0;
  end
end

endmodule
