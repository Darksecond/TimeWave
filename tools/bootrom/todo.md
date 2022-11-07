

make program to run:
```sh
  $(find $(rustc --print sysroot) -name llvm-objcopy) -O binary target/riscv32i-unknown-none-elf/release/bootrom out.bin
```
