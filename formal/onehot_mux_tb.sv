`default_nettype none

module onehot_mux_tb
#(
  parameter Count,
  parameter Width
)
(
  input wire logic [Count-1:0] select_i,
  input wire logic [Width-1:0] words_i [Count],
  input wire logic [Width-1:0] word_o,

  input wire logic [Width-1:0] masked_words [Count]
);

always_comb assume(select_i == 3'b000 || select_i == 3'b001 || select_i == 3'b010 || select_i == 3'b100);

always_comb begin
  case(select_i)
    3'b000: assert(word_o == '0);
    3'b001: assert(word_o == words_i[0]);
    3'b010: assert(word_o == words_i[1]);
    3'b100: assert(word_o == words_i[2]);
    default: assert(0);
  endcase
end

endmodule
