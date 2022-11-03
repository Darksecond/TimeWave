`default_nettype none

module word_reducer
#(
  parameter Count = 0,
  parameter Width = 0
)
(
  input wire logic [Width-1:0] words_in [0:Count-1],
  output logic [Width-1:0] word_out
);

always_comb begin
  for(integer i = 0; i < Width; i = i + 1) begin
    logic [Count-1:0] bits;
    for(integer j = 0; j < Count; j = j + 1) begin
      bits[j] = words_in[j][i];
    end
    word_out[i] = |bits;
  end
end

endmodule
