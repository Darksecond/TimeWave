`default_nettype none

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
