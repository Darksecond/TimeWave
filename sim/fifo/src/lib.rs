verilator::bindings!();

#[allow(dead_code)]
struct Fifo {
    pub sim: Sim,
}

#[allow(dead_code)]
impl Fifo {
    pub fn new() -> Self {
        Self {
            sim: Sim::new(),
        }
    }

    pub fn reset(&mut self) {
        self.sim.set_write_enable(false);
        self.sim.set_read_enable(false);

        self.sim.set_reset_n(false);
        self.sim.set_clk(false);
        self.sim.eval();

        self.sim.set_reset_n(true);
        self.sim.set_clk(false);
        self.sim.eval();
    }

    pub fn negedge(&mut self) {
        self.sim.set_clk(false);
        self.sim.eval();
    }

    pub fn posedge(&mut self) {
        self.sim.set_clk(true);
        self.sim.eval();
    }

    pub fn clock(&mut self) {
        self.posedge();
        self.negedge();
    }

    pub fn prop(&mut self) {
        self.sim.eval();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn initial() {
        let mut fifo = Fifo::new();
        fifo.reset();
        fifo.prop();
        assert_eq!(true, fifo.sim.empty());
        assert_eq!(false, fifo.sim.full());
    }

    #[test]
    fn simple_write() {
        let mut fifo = Fifo::new();
        fifo.reset();

        fifo.sim.set_write_data(0xDEADBEEF);
        fifo.sim.set_write_enable(true);
        fifo.prop();
        fifo.clock();
        assert_eq!(false, fifo.sim.empty());
        assert_eq!(false, fifo.sim.full());
    }

    #[test]
    fn full_write() {
        let mut fifo = Fifo::new();
        fifo.reset();

        for _ in 0..8 {
            fifo.sim.set_write_data(0xDEADBEEF);
            fifo.sim.set_write_enable(true);
            fifo.prop();
            fifo.clock();
        }
        assert_eq!(false, fifo.sim.empty());
        assert_eq!(true, fifo.sim.full());
    }

    #[test]
    fn simple_read() {
        let mut fifo = Fifo::new();
        fifo.reset();

        fifo.sim.set_write_data(0xDEADBEEF);
        fifo.sim.set_write_enable(true);
        fifo.prop();
        fifo.clock();

        fifo.sim.set_write_enable(false);
        fifo.sim.set_read_enable(true);
        fifo.prop();
        fifo.clock();
        assert_eq!(0xDEADBEEF, fifo.sim.read_data());
    }

    #[test]
    fn complex_read() {
        let mut fifo = Fifo::new();
        fifo.reset();

        fifo.sim.set_write_enable(true);
        fifo.sim.set_write_data(0xDEADBEEF);
        fifo.prop();
        fifo.clock();

        fifo.sim.set_write_data(0xFADEBABE);
        fifo.prop();
        fifo.clock();

        fifo.sim.set_write_enable(false);
        fifo.sim.set_read_enable(true);
        fifo.prop();
        fifo.clock();
        assert_eq!(false, fifo.sim.empty());
        assert_eq!(0xDEADBEEF, fifo.sim.read_data());

        fifo.prop();
        fifo.clock();
        assert_eq!(true, fifo.sim.empty());
        assert_eq!(0xFADEBABE, fifo.sim.read_data());
    }

    #[test]
    fn full_write_full_empty() {
        let mut fifo = Fifo::new();
        fifo.reset();

        for _ in 0..8 {
            fifo.sim.set_write_data(0xDEADBEEF);
            fifo.sim.set_write_enable(true);
            fifo.prop();
            fifo.clock();
        }
        assert_eq!(false, fifo.sim.empty());
        assert_eq!(true, fifo.sim.full());

        fifo.sim.set_write_enable(false);
        for _ in 0..8 {
            fifo.sim.set_read_enable(true);
            fifo.prop();
            fifo.clock();
        }
        assert_eq!(true, fifo.sim.empty());
        assert_eq!(false, fifo.sim.full());
    }

    #[test]
    fn no_writethrough() {
        let mut fifo = Fifo::new();
        fifo.reset();

        fifo.sim.set_write_data(0xDEADBEEF);
        fifo.sim.set_write_enable(true);
        fifo.sim.set_read_enable(true);
        fifo.prop();
        assert_eq!(true, fifo.sim.empty());
        fifo.clock();
        assert_eq!(false, fifo.sim.empty());
        fifo.clock();
        assert_eq!(0xDEADBEEF, fifo.sim.read_data());
    }

    #[test]
    fn peek() {
        let mut fifo = Fifo::new();
        fifo.reset();

        fifo.sim.set_write_data(0xDEADBEEF);
        fifo.sim.set_write_enable(true);
        fifo.prop();
        fifo.clock();
        assert_eq!(false, fifo.sim.empty());
        assert_eq!(0xDEADBEEF, fifo.sim.read_data());
    }
}
