/*
.section .init, "ax"
.global _entry

_entry:
j led

lui x1, %hi(0xDEADBEEF)
add x1, x1, %lo(0xDEADBEEF)

lui x2, %hi(0)
add x2, x2, %lo(5)

loop:
addi x2, x2, -1
bne x2, x0, loop

lui x1, %hi(0xFADEBABE)
add x1, x1, %lo(0xFADEBABE)

j _entry


memtest:
// Load 0xDEADBEEF into x1
lui x1, %hi(0xDEADBEEF)
add x1, x1, %lo(0xDEADBEEF)

// Load base store address into x2
lui x2, %hi(0x04)
add x2, x2, %lo(0x04)

// Store x1 into x2+0
sb x1, 5(x2)

// Load x2+0 into x3
lbu x3, 5(x2)

// Loop
j memtest

led:
lui x1, %hi(0x10000000)
add x1, x1, %lo(0x10000000)

lui x2, %hi(0xFF)
add x2, x2, %lo(0xFF)

led_loop:
sw x2, 0(x1)

addi x2, x2, -1

j led_loop
*/

    .section .init, "ax"
    .global _entry
_entry:
    /* Clear bss section */
    lui t0, %hi(_sbss)
    addi t0, t0, %lo(_sbss)
    lui t1, %hi(_ebss)
    addi t1, t1, %lo(_ebss)
    j _clear_bss_loop_end
_clear_bss_loop:
        sw zero, 0(t0)
        addi t0, t0, 4
_clear_bss_loop_end:
    blt t0, t1, _clear_bss_loop

    /* Copy data sections from ROM into RAM, as they need to be writable */
    lui t0, %hi(_sdata)
    addi t0, t0, %lo(_sdata)
    lui t1, %hi(_edata)
    addi t1, t1, %lo(_edata)
    lui t2, %hi(_sidata)
    addi t2, t2, %lo(_sidata)
    j _copy_data_loop_end
_copy_data_loop:
        lw t3, 0(t2)
        sw t3, 0(t0)
        addi t0, t0, 4
        addi t2, t2, 4
_copy_data_loop_end:
    blt t0, t1, _copy_data_loop

    /* Set up env registers */
    .option push
    .option norelax
    lui gp, %hi(__global_pointer$)
    addi gp, gp, %lo(__global_pointer$)
    .option pop

    lui sp, %hi(_stack_start)
    addi sp, sp, %lo(_stack_start)
    lui t0, %hi(_stack_size)
    add t0, t0, %lo(_stack_size)
    sub sp, sp, t0

    add s0, sp, zero

    /* Let's gooooo!! */
    lui t0, %hi(_rust_entry)
    addi t0, t0, %lo(_rust_entry)
    jalr zero, 0(t0)
