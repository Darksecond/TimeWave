`default_nettype none

module fifo
#(
  parameter Width = 0,
  parameter DepthBits = 0,
  localparam Depth = 2**DepthBits,
  localparam CountBits = DepthBits + 1
)
(
  input wire logic clk,
  input wire logic reset_n,

  input wire logic write_enable,
  input wire logic [Width-1:0] write_data,
  output logic full, //TODO write_ready?

  input wire logic read_enable,
  output logic [Width-1:0] read_data,
  output logic empty //TODO read_ready
);

logic [Width-1:0] mem [0:Depth-1];

logic [DepthBits-1:0] read_addr;
logic [DepthBits-1:0] write_addr;

logic [DepthBits-1:0] read_addr_next;
logic [DepthBits-1:0] write_addr_next;

logic [CountBits-1:0] count;
logic [CountBits-1:0] count_next;

logic read_accept;
logic write_accept;

assign full = count[CountBits-1];
assign empty = count == '0;

assign read_accept = read_enable & !empty;
assign write_accept = write_enable & !full;

initial begin
  read_addr = '0;
  write_addr = '0;
  count = '0;
end

always_comb begin
  read_addr_next = read_addr;
  write_addr_next = write_addr;
  count_next = count;

  if(write_accept) begin
    write_addr_next = write_addr + 1;
    count_next = count + 1;
  end

  if(read_accept) begin
    read_addr_next = read_addr + 1;
    count_next = count - 1;
  end

  if(read_accept && write_accept) begin
    count_next = count;
  end
end

always_ff @(posedge clk) begin
  if(!reset_n) begin
    read_addr <= '0;
    write_addr <= '0;
    count <= '0;
  end else begin
    if(write_accept) begin
      mem[write_addr] <= write_data;
    end
    if(read_accept) begin
      read_data <= mem[read_addr];
    end

    read_addr <= read_addr_next;
    write_addr <= write_addr_next;
    count <= count_next;
  end
end

endmodule
