    
    la t1, 480000
    li t6, 120
start:
    li t5, 0
    la t3, 0x80400000
circle:
    li t0, 0
    la t2, 0x01000000
loop:

    # for slow done start
    li a0, 0
    li a1, 28
    la a2, 0x80400000
temp:
    addi a0, a0, 1
    lb t4, 0(a2)
    bne a0, a1, temp
    # for slow done end

    lb t4, 0(t3) # read from ext ram
    sb t4, 0(t2) # store to blk

    addi t0, t0, 16
    addi t2, t2, 1
    addi t3, t3, 1 # ext ram addr
    beq t0, t1, next
    beq zero, zero, loop
next:
    addi t5, t5, 1
    beq t5, t6, start
    beq zero, zero, circle