.section .init, "ax"
.global _entry

_entry:
lui x1, %hi(0xDEADBEEF)
add x1, x1, %lo(0xDEADBEEF)
j _entry
