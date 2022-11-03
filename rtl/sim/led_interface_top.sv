`default_nettype none

module led_interface_master
#(
  localparam DataWidth = 32,
  localparam AddrWidth = 32,
  localparam SelWidth = DataWidth / 8
)
(
  input wire logic clk,
  input wire logic reset_n,

  input wire logic [DataWidth-1:0] bus_data_s,
  input wire logic bus_ack,
  input wire logic bus_stall,
  input wire logic bus_err,

  output logic [DataWidth-1:0] bus_data_m,
  output logic [AddrWidth-1:0] bus_addr,
  output logic [SelWidth-1:0] bus_sel,
  output logic bus_cyc,
  output logic bus_stb,
  output logic bus_we
);

logic [3:0] state;
logic [3:0] state_next;

logic [DataWidth-1:0] value;
logic [DataWidth-1:0] value_next;

initial begin
  state = '0;
  value = '0;
end

always_comb begin
  state_next = state;
  value_next = value;

  bus_data_m = '0;
  bus_addr = '0;
  bus_sel = '0;
  bus_cyc = '0;
  bus_stb = '0;
  bus_we = '0;

  case (state)
    4'h0: begin // Begin read
      bus_cyc = 1'b1;
      bus_stb = 1'b1;
      bus_addr = 32'h20000000;
      if(!bus_stall) begin
        state_next = 4'h1;
      end
    end
    4'h1: begin // Wait for ack
      bus_cyc = 1'b1;
      if(bus_ack) begin
        state_next = 4'h2;
        value_next = bus_data_s;
      end
    end
    4'h2: begin // Idle
      state_next = 4'h3;
    end
    4'h3: begin // Begin write
      bus_cyc = 1'b1;
      bus_stb = 1'b1;
      bus_addr = 32'h10000000;
      bus_sel = 4'h1;
      bus_data_m = value;
      bus_we = 1'b1;
      if(!bus_stall) begin
        state_next = 4'h4;
      end
    end
    4'h4: begin // Wait for ack
      bus_cyc = 1'b1;
      if(bus_ack) begin
        state_next = 4'h5;
      end
    end
    4'h5: begin // Idle
      state_next = 4'h0;
    end
    default: ;
  endcase
end

always_ff @(posedge clk) begin
  if(!reset_n) begin
    state <= '0;
    value <= '0;
  end else begin
    state <= state_next;
    value <= value_next;
  end
end

endmodule

module led_interface_top(
  input wire logic clk,
  input wire logic reset_n,

  output logic [3:0] leds
);

localparam DataWidth = 32;
localparam AddrWidth = 32;
localparam SelWidth = DataWidth / 8;

// Master
logic [DataWidth-1:0] m_data_s;
logic m_ack;
logic m_stall;
logic m_err;
logic [DataWidth-1:0] m_data_m;
logic [AddrWidth-1:0] m_addr;
logic [SelWidth-1:0] m_sel;
logic m_cyc;
logic m_stb;
logic m_we;

// Led
logic [DataWidth-1:0] led_data_s;
logic led_ack;
logic led_stall;
logic led_err;
logic [DataWidth-1:0] led_data_m;
logic [AddrWidth-1:0] led_addr;
logic [SelWidth-1:0] led_sel;
logic led_cyc;
logic led_stb;
logic led_we;

// Rom
logic [DataWidth-1:0] rom_data_s;
logic rom_ack;
logic rom_stall;
logic rom_err;
logic [DataWidth-1:0] rom_data_m;
logic [AddrWidth-1:0] rom_addr;
logic [SelWidth-1:0] rom_sel;
logic rom_cyc;
logic rom_stb;
logic rom_we;

// Dummy
logic [DataWidth-1:0] dummy_data_s;
logic dummy_ack;
logic dummy_stall;
logic dummy_err;
logic [DataWidth-1:0] dummy_data_m;
logic [AddrWidth-1:0] dummy_addr;
logic [SelWidth-1:0] dummy_sel;
logic dummy_cyc;
logic dummy_stb;
logic dummy_we;

wb_multiplexer
#(
  .Count(3),
  .MaskWidth(4)
) wbmux0
(
  .clk,
  .reset_n,

  .m_data_s(m_data_s),
  .m_ack(m_ack),
  .m_stall(m_stall),
  .m_err(m_err),
  .m_data_m(m_data_m),
  .m_addr(m_addr),
  .m_sel(m_sel),
  .m_cyc(m_cyc),
  .m_stb(m_stb),
  .m_we(m_we),

  .s_data_s('{dummy_data_s, led_data_s, rom_data_s }),
  .s_ack('{dummy_ack, led_ack, rom_ack}),
  .s_stall('{dummy_stall, led_stall, rom_stall}),
  .s_err('{dummy_err, led_err, rom_err}),
  .s_data_m('{dummy_data_m, led_data_m, rom_data_m}),
  .s_addr('{dummy_addr, led_addr, rom_addr}),
  .s_sel('{dummy_sel, led_sel, rom_sel}),
  .s_cyc('{dummy_cyc, led_cyc, rom_cyc}),
  .s_stb('{dummy_stb, led_stb, rom_stb}),
  .s_we('{dummy_we, led_we, rom_we})
);

led_interface led0
(
  .clk,
  .reset_n,

  .bus_data_s(led_data_s),
  .bus_ack(led_ack),
  .bus_stall(led_stall),
  .bus_err(led_err),
  .bus_data_m(led_data_m),
  .bus_addr(led_addr),
  .bus_sel(led_sel),
  .bus_cyc(led_cyc),
  .bus_stb(led_stb),
  .bus_we(led_we),

  .leds
);

rom
#(
  .Contents("led.mem"),
  .Depth(5)
) rom0
(
  .clk,

  .bus_data_s(rom_data_s),
  .bus_ack(rom_ack),
  .bus_stall(rom_stall),
  .bus_err(rom_err),
  .bus_data_m(rom_data_m),
  .bus_addr(rom_addr),
  .bus_sel(rom_sel),
  .bus_cyc(rom_cyc),
  .bus_stb(rom_stb),
  .bus_we(rom_we)
);

led_interface_master master0
(
  .clk,
  .reset_n,

  .bus_data_s(m_data_s),
  .bus_ack(m_ack),
  .bus_stall(m_stall),
  .bus_err(m_err),
  .bus_data_m(m_data_m),
  .bus_addr(m_addr),
  .bus_sel(m_sel),
  .bus_cyc(m_cyc),
  .bus_stb(m_stb),
  .bus_we(m_we)
);

endmodule
