`default_nettype none

module uart_tx_tb
#(
  parameter BaudRate,
  parameter ClockFreq,
  localparam CyclesPerBaud = ClockFreq / BaudRate
)
(
  input wire logic clk_i,

  input wire logic valid_i,
  input wire logic ready_o,

  input wire logic [7:0] data_i,

  input wire logic tx_o,

  // Internal
  input wire logic [8:0] data,
  input wire logic [3:0] state,
  input wire logic [23:0] counter
);

logic [7:0] data_f;
logic past_valid;
logic transfer;

initial past_valid = 1'b0;

assign transfer = valid_i && ready_o;

always_ff @(posedge clk_i) past_valid <= 1'b1;

always_ff @(posedge clk_i) begin
  if(valid_i && ready_o) data_f <= data_i;
end

// Cover rising edge of ready_o, this means a full cycle took place.
always_ff @(posedge clk_i) if(past_valid) cover($rose(ready_o));

// Counter can never be higher than CyclesPerBaud.
always_comb assert(counter < CyclesPerBaud);

// State cannot go higher than 10
always_comb assert(state < 11);

initial assert(tx_o == 1);
initial assert(ready_o == 1);

// We become not ready after a valid handshake
always_ff @(posedge clk_i) begin
  if(past_valid && $past(valid_i && ready_o)) begin
    assert(ready_o == 1'b0);
  end
end

// Make sure that the right bits are on the output
always_ff @(posedge clk_i) begin
    case((state))
      0: assert(tx_o == 0);
      1: assert(tx_o == data_f[0]);
      2: assert(tx_o == data_f[1]);
      3: assert(tx_o == data_f[2]);
      4: assert(tx_o == data_f[3]);
      5: assert(tx_o == data_f[4]);
      6: assert(tx_o == data_f[5]);
      7: assert(tx_o == data_f[6]);
      8: assert(tx_o == data_f[7]);
      9: assert(tx_o == 1);
      10: assert(tx_o == 1);
      default: assert(0);
    endcase
end

// Make sure the data is correct
always_ff @(posedge clk_i) begin
  case(state)
    0: assert(data == {data_f, 1'b0});
    1: assert(data == {1'hFF, data_f[7:0]});
    2: assert(data == {2'hFF, data_f[7:1]});
    3: assert(data == {3'hFF, data_f[7:2]});
    4: assert(data == {4'hFF, data_f[7:3]});
    5: assert(data == {5'hFF, data_f[7:4]});
    6: assert(data == {6'hFF, data_f[7:5]});
    7: assert(data == {7'hFF, data_f[7:6]});
    8: assert(data == {8'hFF, data_f[7:7]});
    9: assert(data == 9'h1FF);
    10: assert(data == 9'h1FF);
    default: assert(1);
  endcase
end

// We are not ready when we are sending
always_ff @(posedge clk_i) if(state < 10) assert(ready_o == 0);

// Assume that inputs stay consistent whilst not ready
always_ff @(posedge clk_i) begin
  if(past_valid && $past(valid_i && !ready_o)) begin
    assume($stable(valid_i));
    assume($stable(data_i));
  end
end

endmodule: uart_tx_tb
