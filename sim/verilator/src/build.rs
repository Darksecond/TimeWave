use std::path::{Path, PathBuf};

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

    pub fn build(&mut self, name: &str) {
        self.driver().expect("Could not create driver");
        self.bindings(name).expect("Could not create bindings");
    }

    fn driver(&mut self) -> std::io::Result<()> {
        use std::fs::File;
        use std::io::Write;

        let out = PathBuf::from(std::env::var("OUT_DIR").expect("OUT_DIR not defined"));
        let root = verilator_root().expect("Could not find verilator root");
        let include = root.join("include");
        let module = &self.model.top_module;

        let mut driver = File::create(out.join("driver.cpp")).expect("Could not create file");

        writeln!(driver, "#include <stdint.h>")?;
        writeln!(driver, "#include <V{module}.h>")?;
        writeln!(driver, "")?;
        writeln!(driver, "extern \"C\" {{")?;
        writeln!(driver, "")?;
        writeln!(driver, "V{module} * alloc_{module}() {{")?;
        writeln!(driver, "  return new V{module}();")?;
        writeln!(driver, "}}")?;
        writeln!(driver, "")?;
        writeln!(driver, "void free_{module}(V{module} *sim) {{")?;
        writeln!(driver, "  sim->final();")?;
        writeln!(driver, "  delete sim;")?;
        writeln!(driver, "}}")?;
        writeln!(driver, "")?;
        writeln!(driver, "void eval_{module}(V{module} *sim) {{")?;
        writeln!(driver, "  sim->eval();")?;
        writeln!(driver, "}}")?;

        if self.model.tracing {
            writeln!(driver, "")?;
            writeln!(driver, "void trace_{module}(V{module} *sim, VerilatedVcdC *vcd, uint32_t depth) {{ sim->trace(vcd, depth); }}")?;
        }

        writeln!(driver, "")?;

        for (name, size) in &self.wires {
            writeln!(driver, "{} get_{name}_{module}(V{module} *sim) {{ return sim->{name}; }}", c_type(*size))?;
            writeln!(driver, "void set_{name}_{module}(V{module} *sim, {} value) {{ sim->{name} = value; }}", c_type(*size))?;
        }

        writeln!(driver, "")?;
        writeln!(driver, "}}")?; // extern "C" block

        //TODO rerun-if-changed

        cc::Build::new()
            .cpp(true)
            .include(&include)
            .include(include.join("vltstd"))
            .include(&out.join("verilator"))
            .flag("-std=c++17")
            .file(out.join("driver.cpp"))
            .compile("driver");

        Ok(())
    }

    fn bindings(&mut self, name: &str) -> std::io::Result<()> {
        use std::fs::File;
        use std::io::Write;

        let module = &self.model.top_module;
        let out = PathBuf::from(std::env::var("OUT_DIR").expect("OUT_DIR not defined"));

        let mut bindings = File::create(out.join("bindings.rs")).expect("Could not create file");

        writeln!(bindings, "pub mod ffi {{")?;
        writeln!(bindings, "")?;

        writeln!(bindings, "  #![allow(non_upper_case_globals)]")?;
        writeln!(bindings, "  #![allow(non_camel_case_types)]")?;
        writeln!(bindings, "  #![allow(non_snake_case)]")?;
        writeln!(bindings, "  #![allow(dead_code)]")?;
        writeln!(bindings, "")?;
        writeln!(bindings, "  extern \"C\" {{")?;
        writeln!(bindings, "    pub fn alloc_{module}() -> *mut std::ffi::c_void;")?;
        writeln!(bindings, "    pub fn free_{module}(sim: *mut std::ffi::c_void);")?;
        writeln!(bindings, "    pub fn eval_{module}(sim: *mut std::ffi::c_void);")?;
        writeln!(bindings, "    pub fn trace_{module}(sim: *mut std::ffi::c_void, vcd: *mut std::ffi::c_void, depth: u32);")?;

        for (wire_name, size) in &self.wires {
            writeln!(bindings, "    pub fn get_{wire_name}_{module}(sim: *mut std::ffi::c_void) -> {};", rust_type(*size))?;
            writeln!(bindings, "    pub fn set_{wire_name}_{module}(sim: *mut std::ffi::c_void, value: {});", rust_type(*size))?;
        }

        writeln!(bindings, "  }}")?;
        writeln!(bindings, "}}")?;
        writeln!(bindings, "")?;

        writeln!(bindings, "")?;

        writeln!(bindings, "pub struct {name} {{")?;
        writeln!(bindings, "  ptr: *mut std::ffi::c_void")?;
        writeln!(bindings, "}}")?;
        writeln!(bindings, "")?;

        writeln!(bindings, "impl {name} {{")?;
        writeln!(bindings, "  pub fn new() -> Self {{")?;
        writeln!(bindings, "    unsafe {{")?;
        writeln!(bindings, "      Self {{")?;
        writeln!(bindings, "        ptr: ffi::alloc_{module}(),")?;
        writeln!(bindings, "      }}")?;
        writeln!(bindings, "    }}")?;
        writeln!(bindings, "  }}")?;
        writeln!(bindings, "}}")?;

        writeln!(bindings, "")?;

        writeln!(bindings, "impl Drop for {name} {{")?;
        writeln!(bindings, "  fn drop(&mut self) {{")?;
        writeln!(bindings, "    unsafe {{ ffi::free_{module}(self.ptr); }}")?;
        writeln!(bindings, "  }}")?;
        writeln!(bindings, "}}")?;

        writeln!(bindings, "")?;

        writeln!(bindings, "impl verilator::Model for {name} {{")?;
        writeln!(bindings, "  fn eval(&mut self) {{")?;
        writeln!(bindings, "    unsafe {{ ffi::eval_{module}(self.ptr); }}")?;
        writeln!(bindings, "  }}")?;
        writeln!(bindings, "}}")?;

        if self.model.tracing {
            writeln!(bindings, "")?;
            writeln!(bindings, "impl verilator::Traceable for {name} {{")?;
            writeln!(bindings, "  fn trace(&mut self, vcd: &mut verilator::VcdFile) {{")?;
            writeln!(bindings, "    unsafe {{")?;
            writeln!(bindings, "      ffi::trace_{module}(self.ptr, vcd.ptr, 99);")?;
            writeln!(bindings, "      vcd.open();")?;
            writeln!(bindings, "    }}")?;
            writeln!(bindings, "  }}")?;
            writeln!(bindings, "}}")?;
        }

        writeln!(bindings, "")?;

        writeln!(bindings, "impl {name} {{")?;
        for (wire_name, size) in &self.wires {
            writeln!(bindings, "  pub fn {wire_name}(&self) -> {} {{ unsafe {{ ffi::get_{wire_name}_{module}(self.ptr) }} }}", rust_type(*size))?;
            writeln!(bindings, "  pub fn set_{wire_name}(&mut self, value: {}) {{ unsafe {{ ffi::set_{wire_name}_{module}(self.ptr, value); }} }}", rust_type(*size))?;
        }
        writeln!(bindings, "}}")?;

        //TODO rerun-if-changed

        Ok(())
    }
}
