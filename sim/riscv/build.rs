fn main() {
    use verilator::build::{Verilator, Driver};

    let model = Verilator::new("riscv_top")
        .with_tracing()
        .file("../../rtl/sim/riscv_top.sv")
        .file("../../rtl/alu.sv")
        .file("../../rtl/riscv/riscv_ifu.sv")
        .file("../../rtl/riscv/riscv_regfile.sv")
        .file("../../rtl/riscv/riscv_idu.sv")
        .file("../../rtl/riscv/riscv_csr.sv")
        .file("../../rtl/riscv/riscv_exu.sv")
        .file("../../rtl/riscv/riscv_lsu.sv")
        .file("../../rtl/riscv/riscv_wbu.sv")
        .file("../../rtl/riscv/riscv_hazards.sv")
        .file("../../rtl/riscv/riscv.sv")
        .file("../../rtl/rom.sv")
        .file("../../rtl/ram.sv")
        .file("../../rtl/led_interface.sv")
        .file("../../rtl/wb_multiplexer.sv")
        .file("../../rtl/bus_decoder.sv")
        .build();

    Driver::new(model)
        .wire(1, "clk_i")
        .wire(1, "reset_ni")
        .wire(4, "leds_o")
        .build("Sim");
}
