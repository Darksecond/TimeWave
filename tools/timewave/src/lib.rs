#![no_std]
#![no_main]

pub mod riscv;
pub mod leds;

mod asm {
    use core::arch::global_asm;

    global_asm!(include_str!("_cycles.s"));
    global_asm!(include_str!("_entry.s"));
}

use core::panic::PanicInfo;

#[no_mangle]
extern "C" fn _rust_entry() -> ! {
    extern "Rust" {
        fn main() -> !;
    }

    leds::set(0x00);

    unsafe {
        main();
    }
}

#[panic_handler]
fn panic_handler(_info: &PanicInfo) -> ! {
    loop {
        leds::set(0xFF);
    }
}
