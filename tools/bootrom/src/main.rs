#![no_std]
#![no_main]

use timewave::println;

#[no_mangle]
fn main() -> ! {
    use timewave::{riscv, leds};
    loop {
        println!("Hello, World!");

        leds::set(0xFF);
        riscv::sleep_cycles(riscv::SPEED / 2);
        leds::set(0x00);
        riscv::sleep_cycles(riscv::SPEED / 2);

    }
}
