fn main() {
    use verilator::{Verilator, Driver};

    let model = Verilator::new("riscv_top")
        .with_tracing()
        .file("../../rtl/sim/riscv_top.sv")
        .file("../../rtl/alu.sv")
        .file("../../rtl/riscv/riscv.sv")
        .file("../../rtl/rom.sv")
        .build();

    Driver::new(model)
        .wire(1, "clk_i")
        .wire(1, "reset_ni")
        .wire(4, "leds_o")
        .build();
}
