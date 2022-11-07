`default_nettype none

module cpu_control
#(
)
(
  input wire logic clk,
  input wire logic reset_n,

  input wire logic if_ready,
  output logic if_enable
);

typedef enum logic [2:0] {
  Fetch,
  Decode,
  Execute
} state_t;

state_t state, state_next;

pulse_generator if_enable0
(
  .clk,
  .level_i(state == Fetch),
  .posedge_o(if_enable)
);

always_comb begin
  state_next = state;

  case(state)
    Fetch: begin
      if(if_ready) begin
        state_next = Decode;
      end
    end
    Decode: begin
      state_next = Execute;
    end
    Execute: begin
      state_next = Fetch;
    end
    default: ;
  endcase
end

always_ff @(posedge clk) begin
  if(!reset_n) begin
    state <= Fetch;
  end else begin
    state <= state_next;
  end
end

endmodule

