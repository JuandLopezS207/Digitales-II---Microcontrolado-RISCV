    .text
    .global _start

_main:
    addi x12, x0, 0B11001010
    addi x13, x0, 1
    sw x12, 100(x0)
    lui x14, 4
    sw x12, 4(x14)
    sw x13, 0(x14)
fin: bge x0,x0,fin
