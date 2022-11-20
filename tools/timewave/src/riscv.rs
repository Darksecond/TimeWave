
/// CPU speed of `100MHz`.
pub const SPEED: u64 = 100_000_000;

//pub const SPEED: u64 = 1000;

/// Get current cycle count.
/// This uses the `RDCYCLE` and `RDCYCLEH` CSR.
pub fn cycles() -> u64 {
    extern "C" {
        fn _cycles() -> u64;
    }

    unsafe {
        _cycles()
    }
}

/// Sleep N number of cycles.
pub fn sleep_cycles(count: u64) {
    let start = cycles();
    while cycles() - start < count {
        // Do nothing
    }
}
