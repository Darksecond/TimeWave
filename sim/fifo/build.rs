fn main() {
    use verilator::{Verilator, Driver};

    let model = Verilator::new("fifo_top")
        .with_tracing()
        .file("../../rtl/sim/fifo_top.sv")
        .file("../../rtl/fifo.sv")
        .build();

    Driver::new(model)
        .wire(1, "clk")
        .wire(1, "reset_n")

        .wire(1, "write_enable")
        .wire(32, "write_data")
        .wire(1, "full")

        .wire(1, "read_enable")
        .wire(32, "read_data")
        .wire(1, "empty")
        .build();
}
