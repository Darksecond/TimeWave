use std::path::{PathBuf, Path};

#[macro_export]
macro_rules! bindings {
    () => {
        include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
    }
}

const fn rust_type(size: usize) -> &'static str {
    match size {
        1 => "bool",
        2..=8 => "u8",
        9..=16 => "u16",
        17..=32 => "u32",
        33..=64 => "u64",
        _ => unimplemented!(),
    }
}

const fn c_type(size: usize) -> &'static str {
    match size {
        1 => "bool",
        2..=8 => "uint8_t",
        9..=16 => "uint16_t",
        17..=32 => "uint32_t",
        33..=64 => "uint64_t",
        _ => unimplemented!(),
    }
}

pub fn verilator_root() -> Option<PathBuf> {
    use std::process::Command;
    Command::new("verilator_bin")
        .arg("--getenv")
        .arg("VERILATOR_ROOT")
        .output()
        .ok()
        .map(|output| {
            PathBuf::from(String::from_utf8_lossy(&output.stdout).trim())
        })
}

pub struct Model {
    top_module: String,
    tracing: bool,
}

pub struct Verilator {
    top_module: String,
    files: Vec<PathBuf>,
    tracing: bool,
}

impl Verilator {
    pub fn new(top_module: &str) -> Self {
        Self {
            top_module: top_module.to_owned(),
            files: Vec::new(),
            tracing: false,
        }
    }

    pub fn with_tracing(&mut self) -> &mut Self {
        self.tracing = true;
        self
    }

    pub fn file(&mut self, file: impl AsRef<Path>) -> &mut Self {
        self.files.push(file.as_ref().to_owned());
        self
    }

    pub fn build(&mut self) -> Model {
        self.verilate();
        self.compile();
        Model {
            top_module: self.top_module.clone(),
            tracing: self.tracing,
        }
    }

    fn verilate(&mut self) {
        use regex::Regex;

        use std::process::Command;

        let out = PathBuf::from(std::env::var("OUT_DIR").expect("OUT_DIR not defined"));

        // Cleanup old verilated output.
        let _ = std::fs::remove_dir_all(out.join("verilator"));

        let mut cmd = Command::new("verilator");

        cmd.arg("--cc")
            .arg("-Wall")
            .arg("-Wno-fatal")
            .arg("-Mdir")
            .arg(&out.join("verilator"))
            .arg("--top-module")
            .arg(&self.top_module);

        if self.tracing {
            cmd.arg("--trace");
        }

        for file in &self.files {
            println!("cargo:rerun-if-changed={}", file.to_string_lossy());
            cmd.arg(file);
        }

        let output = cmd.output().expect("Could not run verilator");
        let error_output = std::str::from_utf8(&output.stderr).unwrap();
        let regex = Regex::new(r"%(Error|Warning)(-[A-Z0-9_]+)?: ((\S+):(\d+):((\d+):)? )?.*").unwrap();
        for line in error_output.lines() {
            if regex.is_match(line) {
                println!("cargo:warning={}", line);
            }
        }
        assert!(output.status.success());
    }

    fn compile(&mut self) {
        let out = PathBuf::from(std::env::var("OUT_DIR").expect("OUT_DIR not defined"));
        let root = verilator_root().expect("Could not find verilator root");
        let include = root.join("include");

        let files = std::fs::read_dir(&out.join("verilator")).unwrap()
            .map(|entry| entry.as_ref().unwrap().path())
            .filter(|path| path.extension() == Some(std::ffi::OsStr::new("cpp")));

        cc::Build::new()
            .cpp(true)
            .flag("-std=c++17")
            .include(&include)
            .include(include.join("vltstd"))
            .include(&out.join("verilator"))
            .files(files)
            .compile(&format!("V{}__ALL", &self.top_module));
    }
}

type Wire = (String, usize);
pub struct Driver {
    model: Model,
    wires: Vec<Wire>,
}

impl Driver {
    pub fn new(model: Model) -> Self {
        Self {
            model,
            wires: Vec::new(),
        }
    }

    pub fn wire(&mut self, size: usize, name: &str) -> &mut Self{
        self.wires.push((name.to_owned(), size));
        self
    }

    pub fn build(&mut self) {
        self.driver();
        self.bindings();
    }

    fn driver(&mut self) {
        let out = PathBuf::from(std::env::var("OUT_DIR").expect("OUT_DIR not defined"));
        let root = verilator_root().expect("Could not find verilator root");
        let include = root.join("include");
        let module = &self.model.top_module;

        let mut driver = String::new();

        let mut push = |s: &str| {
            driver.push_str(&format!("{}\n", s));
        };

        push(&format!("
#include <stdint.h>
#include <V{module}.h>

extern \"C\" {{

V{module} * alloc_sim() {{
  return new V{module}();
}}

void free_sim(V{module} *sim) {{
  sim->final();
  delete sim;
}}
void eval(V{module} *sim) {{
  sim->eval();
}}
        "));

        if self.model.tracing {
            push(&format!("void trace(V{module} *sim, VerilatedVcdC *vcd, uint32_t depth) {{ sim->trace(vcd, depth); }}"));
        }

        for (name, size) in &self.wires {
            push(&format!("{} get_{name}(V{module} *sim) {{ return sim->{name}; }}", c_type(*size)));
            push(&format!("void set_{name}(V{module} *sim, {} value) {{ sim->{name} = value; }}", c_type(*size)));
        }

        push("}");

        //TODO rerun-if-changed

        std::fs::write(out.join("driver.cpp"), driver).expect("Could not write driver");

        cc::Build::new()
            .cpp(true)
            .include(&include)
            .include(include.join("vltstd"))
            .include(&out.join("verilator"))
            .flag("-std=c++17")
            .file(out.join("driver.cpp"))
            .compile("driver");
    }

    fn bindings(&mut self) {
        let out = PathBuf::from(std::env::var("OUT_DIR").expect("OUT_DIR not defined"));

        let mut bindings = String::new();
        let mut push = |s: &str| {
            bindings.push_str(&format!("{}\n", s));
        };

        push("pub mod ffi {");

        push("#![allow(non_upper_case_globals)]");
        push("#![allow(non_camel_case_types)]");
        push("#![allow(non_snake_case)]");
        push("#![allow(dead_code)]");
        push("pub type Sim = *mut std::ffi::c_void;");
        push("pub type Vcd = *mut std::ffi::c_void;");
        push("extern {");
        push("pub fn alloc_sim() -> Sim;");
        push("pub fn free_sim(sim: Sim);");
        push("pub fn eval(sim: Sim);");
        push("pub fn trace(sim: Sim, vcd: Vcd, depth: u32);");

        for (name, size) in &self.wires {
            push(&format!("pub fn get_{name}(sim: Sim) -> {};", rust_type(*size)));
            push(&format!("pub fn set_{name}(sim: Sim, value: {});", rust_type(*size)));
        }

        push("}");
        push("}");

        push("pub struct Sim {
            ptr: ffi::Sim,
        }

        impl Sim {
            pub fn new() -> Self {
                unsafe {
                    Self {
                        ptr: ffi::alloc_sim(),
                    }
                }
            }

            pub fn eval(&mut self) {
                unsafe {
                    ffi::eval(self.ptr);
                }
            }
        }

        impl Drop for Sim {
            fn drop(&mut self) {
                unsafe {
                    ffi::free_sim(self.ptr);
                }
            }
        }");

        if self.model.tracing {
            push("impl Sim {
                pub fn trace(&mut self, vcd: &mut verilator::VcdFile) {
                    unsafe {
                        ffi::trace(self.ptr, vcd.ptr, 99);
                        vcd.open();
                    }
                }
            }");
        }

        push("impl Sim {");
        for (name, size) in &self.wires {
            push(&format!("pub fn {name}(&self) -> {} {{ unsafe {{ ffi::get_{name}(self.ptr) }} }}", rust_type(*size)));
            push(&format!("pub fn set_{name}(&mut self, value: {}) {{ unsafe {{ ffi::set_{name}(self.ptr, value); }} }}", rust_type(*size)));
        }
        push("}");

        //TODO rerun-if-changed

        std::fs::write(out.join("bindings.rs"), bindings).expect("Could not write bindings");
    }
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
