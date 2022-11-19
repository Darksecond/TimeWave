#![no_std]
#![no_main]

mod asm {
    use core::arch::global_asm;

    global_asm!(include_str!("entry.s"));
    global_asm!(include_str!("_cycles.s"));
}

use core::panic::PanicInfo;

#[panic_handler]
fn panic_handler(_info: &PanicInfo) -> ! {
    loop {
        // Noop for now
    }
}

#[no_mangle]
extern "C" fn _rust_entry() -> ! {
    main();
}

pub fn cycles() -> u64 {
    extern "C" {
        fn _cycles() -> u64;
    }

    unsafe {
        _cycles()
    }
}

pub fn sleep_cycles(c: u64) {
    let t = cycles();
    while cycles() - t < c {
        // Do nothing
    }
}

fn main() -> ! {

    loop {
        unsafe {
            core::ptr::write_volatile(0x10000000 as *mut u32, 0xFF);
        }

        sleep_cycles(50_000_000);

        unsafe {
            core::ptr::write_volatile(0x10000000 as *mut u32, 0x00);
        }

        sleep_cycles(50_000_000);
    }
}
