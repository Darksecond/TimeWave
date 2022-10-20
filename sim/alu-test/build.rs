
fn main() {
    use verilator::{Verilator, Driver};

    Verilator::new("alu")
        .file("../../rtl/alu.sv")
        .build();

    Driver::new("alu")
        .wire(32, "lhs")
        .wire(32, "rhs")
        .wire(32, "res")
        .build();
}
