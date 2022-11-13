use clap::Parser;
use std::path::PathBuf;
use std::fs::{self, File};
use std::io::Write;

#[derive(Debug, Parser)]
#[command(version)]
struct Args {
    input: PathBuf,
    output: PathBuf,
}

fn main() {
    let args = Args::parse();

    let input = fs::read(&args.input).expect("Could not read input");
    let mut output = File::create(&args.output).expect("Could not create output");

    writeln!(output, "// format=hex addressradix=h dataradix=h version=1.0 wordsperline=1 noaddress").unwrap();

    let mut chunks = input.chunks(4);
    while let Some(chunk) = chunks.next() {
        for _ in 0..4-chunk.len() {
            write!(output, "00").unwrap();
        }
        for byte in chunk.iter().rev() {
            write!(output, "{:02X}", byte).unwrap();
        }
        write!(output, "\n").unwrap();
    }
}
