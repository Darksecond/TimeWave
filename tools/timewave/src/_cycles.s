.section .text.tw_cycles, "ax"
.global _cycles

_cycles:

// We need to loop here according to the RISC-V spec.
rdcycleh a1
rdcycle a0
rdcycleh t0

bne a1, t0, _cycles

ret
