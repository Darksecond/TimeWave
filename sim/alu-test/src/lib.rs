verilator::bindings!();

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let mut sim = Sim::new();
        sim.set_lhs(2);
        sim.set_rhs(1);
        sim.eval();
        assert_eq!(sim.res(), 3);
    }
}
