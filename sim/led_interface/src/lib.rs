verilator::bindings!();

#[cfg(test)]
mod tests {
    use super::*;

    /*
    #[test]
    fn it_works() {
        let mut vcd = verilator::VcdFile::new("test.vcd");
        let mut sim = Sim::new();
        sim.trace(&mut vcd);
        let mut time = 0u32;

        sim.set_reset_n(false);
        sim.set_clk(false);
        sim.eval();
        vcd.dump(time as _);
        time += 1;

        sim.set_reset_n(true);
        sim.set_clk(false);
        sim.eval();
        vcd.dump(time as _);
        time += 1;

        for i in 0..100 {
            sim.set_clk(true);
            sim.eval();
            vcd.dump(time as _);
            time += 1;

            sim.set_write_data(time);
            sim.set_read_req(false);
            sim.set_write_req(false);

            if i == 3 {
                sim.set_write_req(true);
                sim.set_byte_enable(1);
            } else if i == 6 {
                sim.set_read_req(true);
            }

            sim.set_clk(false);
            sim.eval();
            vcd.dump(time as _);
            time += 1;
        }
    }
    */

    #[test]
    fn it_works() {
        let mut vcd = verilator::VcdFile::new("test.vcd");
        let mut sim = Sim::new();
        sim.trace(&mut vcd);
        let mut time = 0u32;

        sim.set_reset_n(false);
        sim.set_clk(false);
        sim.eval();
        vcd.dump(time as _);
        time += 1;

        sim.set_reset_n(true);
        sim.set_clk(false);
        sim.eval();
        vcd.dump(time as _);
        time += 1;

        for _ in 0..1000 {
            sim.set_clk(true);
            sim.eval();
            vcd.dump(time as _);
            time += 1;

            sim.set_clk(false);
            sim.eval();
            vcd.dump(time as _);
            time += 1;
        }
    }
}
