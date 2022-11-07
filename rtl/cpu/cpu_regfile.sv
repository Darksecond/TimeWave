`default_nettype none

module cpu_regfile
#(
  localparam Count = 32,
  localparam DataWidth = 32,
  localparam AddrWidth = 5
)
(
  input wire logic clk,
  input wire logic reset_n,

  input wire logic [DataWidth-1:0] write_data_i,
  input wire logic [AddrWidth-1:0] write_addr_i,
  input wire logic write_enable_i,

  input wire logic [AddrWidth-1:0] read0_addr_i,
  output logic [DataWidth-1:0] read0_data_o,

  input wire logic [AddrWidth-1:0] read1_addr_i,
  output logic [DataWidth-1:0] read1_data_o
);

logic [DataWidth-1:0] regs[Count];

initial begin
  for(int i = 0; i < Count; i+= 1) begin
    regs[i] = i;
  end
end

always_ff @(posedge clk) begin
  if(write_enable_i && write_addr_i != '0) begin
    regs[write_addr_i] <= write_data_i;
  end
  read0_data_o <= regs[read0_addr_i];
  read1_data_o <= regs[read1_addr_i];
end

endmodule;
