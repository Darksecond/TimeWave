#![no_std]
#![no_main]

mod asm {
    use core::arch::global_asm;

    global_asm!(include_str!("entry.s"));
}

use core::panic::PanicInfo;

#[panic_handler]
fn panic_handler(_info: &PanicInfo) -> ! {
    loop {
        // Noop for now
    }
}
