use std::env;
use std::path::Path;
use std::fs;

fn main() {
    let out_dir = env::var("OUT_DIR").expect("No out dir");
    let dest_path = Path::new(&out_dir);

    fs::write(&dest_path.join("link.ld"), include_bytes!("link.ld")).expect("Could not write file");

    println!("cargo:rustc-link-search={}", dest_path.display());
    println!("cargo:rerun-if-changed=link.ld");
}
