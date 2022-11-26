use core::ptr;

const UART: *mut u32 = 0x20000000 as _;

fn is_ready() -> bool {
    unsafe {
        let val = ptr::read_volatile(UART);
        val & 0x100 == 1
    }
}

pub fn write_char(value: char) {
    let value = value as u8;

    while !is_ready() {}
    unsafe {
        ptr::write_volatile(UART, value as u32);
    }
}
