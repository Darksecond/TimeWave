use std::path::{PathBuf, Path};

#[macro_export]
macro_rules! bindings {
    () => {
        include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
    }
    /*
    ($m:ident) => {
        mod $m {
            #![allow(non_upper_case_globals)]
            #![allow(non_camel_case_types)]
            #![allow(non_snake_case)]
            #![allow(dead_code)]

            include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
        }
    }
    */
}

const fn rust_type(size: usize) -> &'static str {
    match size {
        1..=8 => "u8",
        9..=16 => "u16",
        17..=32 => "u32",
        33..=64 => "u64",
        _ => unimplemented!(),
    }
}

const fn c_type(size: usize) -> &'static str {
    match size {
        1..=8 => "uint8_t",
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

pub struct Verilator {
    top_module: String,
    files: Vec<PathBuf>,
}

impl Verilator {
    pub fn new(top_module: &str) -> Self {
        Self {
            top_module: top_module.to_owned(),
            files: Vec::new(),
        }
    }

    pub fn file(&mut self, file: impl AsRef<Path>) -> &mut Self {
        self.files.push(file.as_ref().to_owned());
        self
    }

    pub fn build(&mut self) {
        self.verilate();
        self.compile();
    }

    fn verilate(&mut self) {
        use std::process::Command;

        let out = PathBuf::from(std::env::var("OUT_DIR").expect("OUT_DIR not defined"));

        let mut cmd = Command::new("verilator");

        cmd.arg("--cc")
            .arg("-Wall")
            .arg("-Mdir")
            .arg(&out.join("verilator"))
            .arg("--top-module")
            .arg(&self.top_module);

        for file in &self.files {
            println!("cargo:rerun-if-changed={}", file.to_string_lossy());
            cmd.arg(file);
        }

        let output = cmd.output().expect("Could not run verilator");
        eprintln!("{}", std::str::from_utf8(&output.stderr).unwrap());
        //TODO print warnings
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
    top_module: String,
    wires: Vec<Wire>,
}

impl Driver {
    pub fn new(top_module: &str) -> Self {
        Self {
            top_module: top_module.to_owned(),
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
        let module = &self.top_module;

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
  delete sim;
}}
void eval(V{module} *sim) {{
  sim->eval();
}}
        "));

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
        push("extern {");
        push("pub fn alloc_sim() -> Sim;");
        push("pub fn free_sim(sim: Sim);");
        push("pub fn eval(sim: Sim);");

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
