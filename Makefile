
OBJCOPY=$$(find $$(rustc --print sysroot) -name llvm-objcopy)

BOOTROM_ELF=tools/bootrom/target/riscv32i-unknown-none-elf/release/bootrom
BOOTROM_BIN=tools/bootrom/target/riscv32i-unknown-none-elf/release/bootrom.bin
BOOTROM_MEM=rom/bootrom.mem

.PHONY: all
all: $(BOOTROM_MEM)

.PHONY: $(BOOTROM_ELF)
$(BOOTROM_ELF):
	cd tools/bootrom && cargo build --release

$(BOOTROM_BIN): $(BOOTROM_ELF)
	$(OBJCOPY) -O binary $< $@

$(BOOTROM_MEM): $(BOOTROM_BIN)
	cd tools/memgen && cargo build --release
	tools/memgen/target/release/memgen $< $@

.PHONY: clean
clean:
	cd tools/bootrom && cargo clean
	rm -f $(BOOTROM_BIN)
	rm -f $(BOOTROM_MEM)
