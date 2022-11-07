fn main() {
    use verilator::{Verilator, Driver};

    let model = Verilator::new("led_interface_top")
        .with_tracing()
        .file("../../rtl/rom.sv")
        .file("../../rtl/ram.sv")
        .file("../../rtl/pulse_latch.sv")
        .file("../../rtl/pulse_generator.sv")
        .file("../../rtl/cpu/cpu.sv")
        .file("../../rtl/cpu/cpu_if.sv")
        .file("../../rtl/cpu/cpu_control.sv")
        .file("../../rtl/cpu/cpu_regfile.sv")
        .file("../../rtl/cpu/cpu_decode.sv")
        .file("../../rtl/cpu/cpu_execute.sv")
        .file("../../rtl/led_interface.sv")
        .file("../../rtl/wb_multiplexer.sv")
        .file("../../rtl/bus_decoder.sv")
        .file("../../rtl/sim/led_interface_top.sv")
        .build();

    Driver::new(model)
        .wire(1, "clk")
        .wire(1, "reset_n")
        .wire(4, "leds")
        .build();
}
