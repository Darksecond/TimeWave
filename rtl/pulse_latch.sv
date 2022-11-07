`default_nettype none

module pulse_latch
(
  input wire logic clk,

  input wire logic pulse_i,
  input wire logic clear_i,

  output logic level_o
);

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
