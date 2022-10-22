
fn main() {
    use verilator::{Verilator, Driver};

    let model = Verilator::new("alu")
        //.with_tracing()
        .file("../../rtl/alu.sv")
        .build();

    Driver::new(model)
        .wire(2, "cmd")
        .wire(32, "lhs")
        .wire(32, "rhs")
        .wire(32, "res")
        .build();
}
