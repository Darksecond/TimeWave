`default_nettype none

module priority_arbiter
#(
  parameter Count = 0
)
(
  input wire logic clk_i,

  input wire logic [Count-1:0] requests_i,
  output logic [Count-1:0] grant_o
);

logic [Count-1:0] grant_q;
logic [Count-1:0] lsb;

assign lsb = requests_i & (-requests_i);

initial grant_q = '0;

always_comb begin
  grant_o = ((requests_i & grant_q) != '0) ? grant_q : lsb;
end

always_ff @(posedge clk_i) begin
  grant_q <= grant_o;
end

// Formal
`ifdef FORMAL
  priority_arbiter_tb
  #(
    .Count(Count)
  ) tb0(.*);
`endif

endmodule
