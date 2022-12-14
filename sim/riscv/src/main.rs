verilator::bindings!();
use verilator::{Model, Traceable};

struct Riscv {
    vcd: verilator::VcdFile,
    sim: Sim,
    time: u64,
}

impl Riscv {
    pub fn new() -> Self {
        let mut vcd = verilator::VcdFile::new("trace.vcd");
        let mut sim = Sim::new();
        sim.trace(&mut vcd);
        return Self {
            vcd,
            sim,
            time: 0,
        }
    }

    pub fn cycle(&mut self) {
        self.sim.set_clk_i(true);
        self.sim.eval();
        self.vcd.dump(self.time as _);
        self.time += 1;

        self.sim.set_clk_i(false);
        self.sim.eval();
        self.vcd.dump(self.time as _);
        self.time += 1;
    }

    pub fn reset(&mut self) {
        self.sim.set_reset_ni(false);
        self.cycle();

        self.sim.set_reset_ni(true);
        self.sim.eval();
    }
}

fn main() {
    let mut led = 0;
    let mut riscv = Riscv::new();

    riscv.reset();

    for _ in 0..10000 {
        riscv.cycle();

        if led != riscv.sim.leds_o() {
            println!("0b{:08b}", riscv.sim.leds_o());
        }
        led = riscv.sim.leds_o();
    }
}
