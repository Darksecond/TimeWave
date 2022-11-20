use core::ptr;

//TODO Rewrite for easier colour support.

const LEDS: *mut u32 = 0x10000000 as _;

/// Set the value of the leds register.
/// Format is: `0xXX_XX_XX_XW` where `W` is white.
pub fn set(value: u32) {
    unsafe {
        ptr::write_volatile(LEDS, value);
    }
}
