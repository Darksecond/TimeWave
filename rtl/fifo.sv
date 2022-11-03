`default_nettype none

module fifo
#(
  parameter Width = 0,
  parameter DepthBits = 0,
  localparam Depth = 2**DepthBits
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
logic [DepthBits-1:0] read_addr_next;

logic [DepthBits-1:0] write_addr;
logic [DepthBits-1:0] write_addr_next;

logic read_accept;
logic write_accept;

assign empty = write_addr == read_addr;
assign full = write_addr + 1'b1 == read_addr;

assign read_accept = read_enable & !empty;
assign write_accept = write_enable & ((!full) || read_enable);

initial begin
  read_addr = '0;
  write_addr = '0;
end

always_comb begin
  read_addr_next = read_addr;
  write_addr_next = write_addr;

  if(write_accept) begin
    write_addr_next = write_addr + 1'b1;
  end

  if(read_accept) begin
    read_addr_next = read_addr + 1'b1;
  end
end

always_ff @(posedge clk) begin
  if(!reset_n) begin
    read_addr <= '0;
    write_addr <= '0;
  end else begin

    mem[write_addr] <= write_data;

    if(empty && write_enable) begin
      read_data <= write_data;
    end else begin
      read_data <= mem[read_addr];
    end

    read_addr <= read_addr_next;
    write_addr <= write_addr_next;

  end
end

endmodule
