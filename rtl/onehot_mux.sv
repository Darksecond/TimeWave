`default_nettype none

module onehot_mux
#(
  parameter Count = 0,
  parameter Width = 0
)
(
  input wire logic [Count-1:0] select,
  input wire logic [Width-1:0] words_in [0:Count-1],
  output logic [Width-1:0] word_out
);

logic [Width-1:0] masked_words [0:Count-1];

always_comb begin
  for(integer i = 0; i < Count; i = i + 1) begin
    masked_words[i] = select[i] ? words_in[i] : '0;
  end
end

word_reducer
#(
  .Width(Width),
  .Count(Count)
) reducer0
(
  .words_in(masked_words),
  .word_out(word_out)
);

endmodule;
