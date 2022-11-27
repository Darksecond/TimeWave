`default_nettype none

module priority_arbiter_tb
#(
  parameter Count
)
(
  input wire logic clk_i,

  input wire logic [Count-1:0] requests_i,
  input wire logic [Count-1:0] grant_o,

  input wire logic [Count-1:0] grant_q,
  input wire logic [Count-1:0] lsb
);

logic past_valid;

initial past_valid = 1'b0;

always_ff @(posedge clk_i) past_valid <= 1'b1;

always_ff @(posedge clk_i) begin
  // We hold a previously held grant
  if(past_valid && ((requests_i & $past(grant_o)) != '0)) begin
    assert(grant_o == $past(grant_o));
  end

  // New grants are given based on priority
  if(past_valid && ((requests_i & $past(grant_o)) == '0)) begin
    casez(requests_i)
      3'b000: assert(grant_o == 3'b000);
      3'b??1: assert(grant_o == 3'b001);
      3'b?10: assert(grant_o == 3'b010);
      3'b100: assert(grant_o == 3'b100);
      default: assert(0);
    endcase
  end
end

always_comb begin
  case(grant_o)
    3'b000: assert(1);
    3'b001: assert(1);
    3'b010: assert(1);
    3'b100: assert(1);
    default: assert(0);
  endcase
end

endmodule
