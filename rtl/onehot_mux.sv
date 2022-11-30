`default_nettype none

module onehot_mux
#(
  parameter Count,
  parameter Width
)
(
  input wire logic [Count-1:0] select_i,
  input wire logic [Width-1:0] words_i [Count],

  output logic [Width-1:0] word_o
);

logic [Count-1:0][Width-1:0] masked_words;

always_comb begin
  for(integer i = 0; i < Count; i = i + 1) begin
    masked_words[i] = select_i[i] ? words_i[i] : '0;
  end
end

always_comb begin
  for(integer i = 0; i < Width; i = i + 1) begin
    logic [Count-1:0] bits;
    for(integer j = 0; j < Count; j = j + 1) begin
      bits[j] = masked_words[j][i];
    end
    word_o[i] = |bits;
  end
end

// Formal
`ifdef FORMAL
  onehot_mux_tb
  #(
    .Count(Count),
    .Width(Width)
  ) tb0(.*);
`endif

endmodule
