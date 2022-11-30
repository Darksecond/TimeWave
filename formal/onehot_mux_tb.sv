`default_nettype none

`ifdef ONEHOT_MUX
  `define ASSUME assume
`else
  `define ASSUME assert
`endif

module onehot_mux_tb
#(
  parameter Count,
  parameter Width
)
(
  input wire logic [Count-1:0] select_i,
  input wire logic [Width-1:0] words_i [Count],
  input wire logic [Width-1:0] word_o,

  input wire logic [Count-1:0][Width-1:0] masked_words
);

logic [Count-1:0] select_bits;
bitcount_tbu
#(
  .Width(Count)
) onehot0
(
  .word_i(select_i),
  .width_o(select_bits)
);

always_comb `ASSUME(select_bits < 2);

always_comb begin
  assert(word_o == '0 || word_o == words_i[0] || word_o == words_i[1] || word_o == words_i[2]);
  case(select_i)
    3'b000: assert(word_o == '0);
    3'b001: assert(word_o == words_i[0]);
    3'b010: assert(word_o == words_i[1]);
    3'b100: assert(word_o == words_i[2]);
    default: assert(0);
  endcase
end

endmodule

//TODO MOVE TO it's own file.
/// Testbench Utility, Bit Count.
/// This counts the number of bits in a given word.
//  This can be used to emulate $onehot (assume/assert bitcount < 2)
module bitcount_tbu
#(
  parameter Width
)
(
  input wire logic [Width-1:0] word_i,
  output logic [Width-1:0] width_o
);

logic [Width-1:0][Width-1:0] count;

assign width_o = count[Width-1];
assign count[0] = word_i[0];

always_comb begin
  for(integer i=1;i<Width;i+=1) begin
    count[i] = count[i-1] + word_i[i];
  end
end


endmodule
