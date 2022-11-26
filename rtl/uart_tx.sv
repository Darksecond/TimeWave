`default_nettype none

module uart_tx
#(
  parameter BaudRate = 57600,
  parameter ClockFreq = 100_000_000, // 100MHz
  localparam CyclesPerBaud = ClockFreq / BaudRate
)
(
  input wire logic clk_i,

  input wire logic valid_i,
  output logic ready_o,

  input wire logic [7:0] data_i,

  output logic tx_o
);

localparam Start = 4'd0;
localparam Stop = 4'd9;
localparam Idle = 4'd10;

logic baud_stb;
logic [8:0] data;
logic [3:0] state;
logic [23:0] counter;
logic transfer;

initial data = 9'h1FF;
initial state = Idle;
initial ready_o = '1;

assign transfer = valid_i && ready_o;
assign tx_o = data[0];

always_ff @(posedge clk_i) begin
  if(transfer) begin
    ready_o <= 0;
  end else if(state == Stop && baud_stb) begin // Next state is Idle
    ready_o <= 1;
  end else if(state < Stop) begin
    ready_o <= 0;
  end
end

always_ff @(posedge clk_i) begin
  if(transfer) begin
    state <= Start;
  end else if(state == Idle) begin
    state <= Idle;
  end else if(baud_stb) begin
    state <= state + 1;
  end
end

always_ff @(posedge clk_i) begin
  if(transfer) begin
    data <= {data_i, 1'b0};
  end else if(baud_stb) begin
    data <= {1'b1, data[8:1]};
  end
end

// Clock logic
assign baud_stb = counter == 0;
initial counter = 0;
always_ff @(posedge clk_i) begin
  if(transfer) begin
    counter <= CyclesPerBaud - 1;
  end else if(counter > 0) begin
    counter <= counter - 1;
  end else begin
    counter <= CyclesPerBaud - 1;
  end
end

// Formal
`ifdef FORMAL
  uart_tx_tb
  #(
    .BaudRate(BaudRate),
    .ClockFreq(ClockFreq)
  ) tb0(.*);
`endif

endmodule: uart_tx
