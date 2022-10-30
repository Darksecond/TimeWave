fn main() {
    use verilator::{Verilator, Driver};

    let model = Verilator::new("led_interface_top")
        .with_tracing()
        .file("../../rtl/rom.sv")
        .file("../../rtl/led_interface.sv")
        .file("../../rtl/system_bus.sv")
        .file("../../rtl/priority_encoder.sv")
        .file("../../rtl/multiplexer.sv")
        .file("../../rtl/bus.sv")
        .file("../../rtl/bus_decoder.sv")
        .file("../../rtl/sim/led_interface_top.sv")
        .build();

    /*
    Driver::new(model)
        .wire(1, "clk")
        .wire(1, "reset_n")

        .wire(1, "write_req")
        .wire(32, "write_data")
        .wire(4, "byte_enable")

        .wire(1, "read_req")
        .wire(32, "read_data")
        .wire(1, "read_data_valid")

        .wire(4, "leds")
        .build();
    */

    Driver::new(model)
        .wire(1, "clk")
        .wire(1, "reset_n")
        .wire(4, "leds")
        .build();
}
