`default_nettype none

module priority_arbiter
#(
  parameter Count = 0
)
(
  input wire logic clk,
  input wire logic reset_n,

  input wire logic [Count-1:0] requests,
  output logic [Count-1:0] grant
);

logic [Count-1:0] grant_reg;
logic [Count-1:0] lsb;

assign lsb = requests & (-requests);

initial begin
  grant_reg = '0;
end

always_comb begin
  grant = ((requests & grant_reg) != '0) ? grant_reg : lsb;
end

always_ff @(posedge clk) begin
  if(!reset_n) begin
    grant_reg <= '0;
  end else begin
    grant_reg <= grant;
  end
end

endmodule
