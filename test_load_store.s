addi x5, x0, 12
sw x5, 0x10(x0)
addi x5, x0, 23
sw x5, 0x14(x0)
lw x5, 0x10(x0)
lw x6, 0x14(x0)
add x7, x5, x6
sw x7, 0x18(x0)
