.section .init, "ax"
.global _entry

_entry:
j memtest

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
