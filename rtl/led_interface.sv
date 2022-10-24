`default_nettype none

module led_interface(
  input wire logic clk,
  input wire logic reset_n,

  input wire logic write_req,
  input wire logic [31:0] write_data,
  input wire logic [3:0] byte_enable,

  input wire logic read_req,
  output wire logic [31:0] read_data,
  output logic read_data_valid,

  output logic [3:0] leds);

logic read_data_valid_next;
logic [3:0] leds_next;

assign read_data = {28'h0, leds};

always_comb begin
  read_data_valid_next = read_data_valid;
  leds_next = leds;

  read_data_valid_next = read_req;
  if (write_req && byte_enable[0]) begin
    leds_next = write_data[3:0];
  end
end

always_ff @(posedge clk) begin
  if(!reset_n) begin
    read_data_valid <= 1'h0;
    leds <= 4'h0;
  end else begin
    read_data_valid <= read_data_valid_next;
    leds <= leds_next;
  end
end

endmodule
