# x3 = 30; SRAM[0x10000000] = 30; x5 = 30
addi x1, x0, 10
addi x2, x0, 20
add  x3, x1, x2
lui  x4, 0x10000
sw   x3, 0(x4)
lw   x5, 0(x4)
done: jal x0, done
