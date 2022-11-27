`default_nettype none

module word_reducer
#(
  parameter Count = 0,
  parameter Width = 0
)
(
  input wire logic [Width-1:0] words_i [Count],
  output logic [Width-1:0] word_o
);

always_comb begin
  for(integer i = 0; i < Width; i = i + 1) begin
    logic [Count-1:0] bits;
    for(integer j = 0; j < Count; j = j + 1) begin
      bits[j] = words_i[j][i];
    end
    word_o[i] = |bits;
  end
end

endmodule
