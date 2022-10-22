use std::path::PathBuf;

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

pub fn main() {
    let root = verilator_root().expect("Could not find verilator root");
    let include = root.join("include");

    let files = vec![
        "verilated.cpp",
        "verilated_cov.cpp",
        "verilated_dpi.cpp",
        "verilated_fst_c.cpp",
        "verilated_save.cpp",
        "verilated_vcd_c.cpp",
        "verilated_vpi.cpp",
    ];

    let files: Vec<PathBuf> = files.iter().map(|p| include.join(p)).collect();

    cc::Build::new()
        .cpp(true)
        .flag("-std=c++17")
        .include(&include)
        .include(include.join("vltstd"))
        .files(files)
        .file("src/shim.cpp")
        .compile("verilated_all");
}
