`default_nettype none

module priority_encoder
#(
  parameter Count = 0,
  localparam CountBits = $clog2(Count)
)
(
  input wire logic [Count-1:0] requests,
  output logic [CountBits-1:0] select,
  output logic select_valid
);

logic [Count-1:0] lsb;

assign lsb = requests & (-requests);
assign select_valid = lsb != '0;

logic [CountBits-1:0] logs [0:Count-1];

for (genvar i = 0; i < Count; i = i + 1) begin
  always_comb begin
    logs[i] = (requests[i] == 1'b1) ? i[CountBits-1:0] : '0;
  end
end

logic [Count-1:0] bits [0:CountBits-1];
for (genvar i = 0; i < Count; i = i + 1) begin
  for (genvar j = 0; j < CountBits; j = j + 1) begin
    assign bits[j][i] = logs[i][j];
    assign select[j] = |bits[j];
  end
end

endmodule
