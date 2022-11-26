#![no_std]
#![no_main]

#[no_mangle]
fn main() -> ! {
    use timewave::{riscv, leds, uart};
    loop {
        leds::set(0xFF);
        riscv::sleep_cycles(riscv::SPEED / 2);
        leds::set(0x00);
        riscv::sleep_cycles(riscv::SPEED / 2);

        uart::write_char('A');
    }
}
