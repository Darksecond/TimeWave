.section .init, "ax"
.global _entry

_entry:
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
