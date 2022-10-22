verilator::bindings!();

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        //let mut vcd = verilator::VcdFile::new("test.vcd");
        let mut sim = Sim::new();
        //sim.trace(&mut vcd);

        //vcd.dump(0);

        sim.set_cmd(0);
        sim.set_lhs(2);
        sim.set_rhs(1);
        sim.eval();

        assert_eq!(sim.res(), 3);
    }
}
