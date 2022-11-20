pub mod build;

use std::path::Path;

#[macro_export]
macro_rules! bindings {
    () => {
        include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
    }
}

pub trait Model {
    fn eval(&mut self);
}

pub trait Traceable {
    fn trace(&mut self, vcd: &mut VcdFile);
}

mod ffi {
    extern "C" {
        pub fn alloc_vcd() -> *mut std::ffi::c_void;
        pub fn open_vcd(vcd: *mut std::ffi::c_void, file: *const std::ffi::c_char);
        pub fn free_vcd(vcd: *mut std::ffi::c_void);
        pub fn dump_vcd(vcd: *mut std::ffi::c_void, time: u64);
    }
}

pub struct VcdFile {
    file: std::ffi::CString,
    pub ptr: *mut std::ffi::c_void,
    is_open: bool,
}

impl VcdFile {
    pub fn new(file: impl AsRef<Path>) -> Self {
        let file = std::ffi::CString::new(file.as_ref().to_string_lossy().as_bytes()).unwrap();
        Self {
            file,
            ptr: unsafe { ffi::alloc_vcd() },
            is_open: false
        }
    }

    pub fn open(&mut self) {
        assert!(!self.is_open);
        self.is_open = true;
        unsafe {
            ffi::open_vcd(self.ptr, self.file.as_ptr());
        }
    }

    pub fn dump(&mut self, time: u64) {
        unsafe {
            ffi::dump_vcd(self.ptr, time);
        }
    }
}

impl Drop for VcdFile {
    fn drop(&mut self) {
        unsafe {
            if self.is_open {
                ffi::free_vcd(self.ptr);
            }
        }
    }
}
