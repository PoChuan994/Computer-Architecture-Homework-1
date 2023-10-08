.data
    test_data_1: .dword 0x0123456789abc123
    test_data_2: .dword 0x0111000000000000
    test_data_3: .dword 0x0000000000f00000
.text    
main:
    # initial setting
    addi   a1, zero, 4       # int n
    lui    a5, 0xfffff
    srai   a5, a5, 12        # a5 = 0xffffffff

    # test data setting
    #lui    a2, 0x01234       # upper bits of test data 1
    #addi   a2, a2, 0x567     # upper bits of test data 1
    #lui    a3, 0x89abc       # lower bits if test data 1
    #addi   a3, a3, 0x123     # upper bits of test data 1
    # for test
    lui     a2, 0x0f000
    add a3, zero, zero
    
main_for_loop:
    jal    ra, finding_string        # jump to find_string procedure
    # tmp for test
    add    zero, zero, zero

# finding_string procedure
finding_string:
    # preserved return address, test data
    addi    sp, sp, -12
    sw      ra, 0(sp)
    sw      a2, 4(sp)
    sw      a3, 8(sp)                        
    # initial setting
    add    s0, zero, zero    # int clz 
    add    s1, zero, zero    # int pos = 0
finding_string_while_loop:
    # check whether x equals to zero
    bne    a2, zero, 24
    bne    a3, zero, 20
    addi   a0, zero, -1    # not found, return -1
    addi   sp, sp, -4
    sw     a0, 0(sp)
    jalr   ra              # not found, return control to main
    jal    ra, CLZ
    lw     a0, 0(sp)
    addi   sp, sp, 4
    add    s0, a0, zero    # s0 = clz
    # x = x << clz
    addi   t3, zero, 32
    sub    t3, t3, s0
    srl    t3, a3, t3
    sll    t2, a2, s0
    or     s2, t2, t3    # s2 = [0~31] x << clz
    sll    s3, a3, s0    # s3 = [32~63] x << clz
    # pos = pos + clz
    add    s1, s1, s0
    # x = ~ x
    xor    a2, s2, a5
    xor    a3, s3, a5    # [a2, a3] = ~x
    jal    ra, CLZ
    lw     a0, 0(sp)
    addi   sp, sp, 4
    add    s0, a0, zero    # s0 = clz
    
    bge    s0, a0, 36
    # < case
    addi   t3, zero, 32
    sub    t3, t3, s0
    srl    t5, s3, t3
    sll    t4, s2, s0
    or     a2, t4, t5
    sll    a3, s3, s0
    add    s1, s1, s0
    beq    zero, zero,   finding_string_while_loop 
    # >= case
    lw     ra, 0(sp)
    lw     a2, 0(sp)
    lw     a3, 0(sp)
    addi   sp, sp, 8   
#    addi   sp, sp, -4
    sw     s1, 0(sp)
    jalr   ra

    #blt    s0, a1, 12    # if  (CLZ(number of continuous 1 bits)) < n then jump
    #addi   sp, sp, -4
    #sw     s1, 0(sp)
    # x = x << clz
    #addi   t3, zero, 32
    #sub    t3, t3, s0
    #srl    t5, s3, t3
    #sll    t4, s2, s0
    #or     a2, t4, t5
    #sll    a3, s3, s0
    #add    s1, s1, s0
    #beq    zero, zero,   finding_string_while_loop 

# counting_leading_zero procedure
CLZ:
    addi   sp, sp, -4
    sw     ra, 0(sp)
    
    # x |= (x>>1)    
    srli    t1, a3, 1       # shift lower bits of test data right with 1 bit
    slli    t0, a2, 31      # shift upper bits of test data left with 31 bits
    or      t1, t1, t0      # combine to get new lower bit of test data (after srl)
    srli    t0, a2, 1       # shift upper bits of test data right with 1 bit
    or      t0, t0, a2      # [0~31]x | [0~31](x>>1)
    or      t1, t1, a3      # [32~63]x | [32~63](x>>1)
    # value of x is stored in t0, t1 ([0~31], [32~63])

    # x |= (x>>2)
    srli    t3, t1, 2
    slli    t2, t0, 30
    or      t3, t3, t2
    srli    t2, t0, 2
    or      t0, t2, t0
    or      t1, t3, t1

    # x |= (x>>4)
    srli    t3, t1, 4
    slli    t2, t0, 28
    or      t3, t3, t2
    srli    t2, t0, 4
    or      t0, t2, t0
    or      t1, t3, t1
    
    # x |= (x>>8)
    srli    t3, t1, 8
    slli    t2, t0, 24
    or      t3, t3, t2
    srli    t2, t0, 8
    or      t0, t2, t0
    or      t1, t3, t1

    # x |= (x>>16)
    srli    t3, t1, 16
    slli    t2, t0, 16
    or      t3, t3, t2
    srli    t2, t0, 16
    or      t0, t2, t0
    or      t1, t3, t1

    # x |= (x>>32)
    add     t3, t0, zero
    add     t2, zero, zero
    or      t0, t0, t2
    or      t1, t1, t3

    # x -= ((x>>1) & 0x5555555555555555)
    srli    t3, t1, 1    
    slli    t2, t0, 31
    or      t3, t3, t2
    srli    t2, t0, 1    # [t2, t3] = (x>>1)
    lui     t4, 0x55555    
    addi    t4, t4, 0x555    # t4=0x55555555
    and     t2, t2, t4
    and     t3, t3, t4    # [t2, t3] = (x>>1)&0x5555555555555555
    sub     t3, t1, t3    
    blt     t1, t3, 16    # if underflow then jump
    add     t1, t3, zero    # t1=t3
    sub     t0, t0, t2    # no underflow at lower bits, [t0, t1]=> x -= ((x>>1) & 0x5555555555555555)
    beq     zero, zero, 12
    addi    t0, t0, -1    # underflow at lower bits
    sub     t0, t0, t2        #[t0, t1] => x -= ((x>>1) & 0x5555555555555555)  
    
    # x = ((x>>2)&0x333333333333333) + (x & 0x3333333333333333) 
    srli    t3, t1, 2
    slli    t2, t0, 30
    or      t3, t3, t2
    srli    t2, t0, 2    # [t2, t3] = x>>2
    lui     t4, 0x33333    
    addi    t4, t4, 0x333    # t4=0x33333333
    and     t2, t2, t4
    and     t3, t3, t4    # [t2, t3] = ((x>>2)&0x333333333333333)
    and     t0, t0, t4
    and     t1, t1, t4    # [t0, t1] = (x&0x333333333333333)    
    add     t1, t1, t3
    add     t0, t0, t2
    ## overflow detection (lower bits)
    lui t4, 0xfffff
    srai t4, t4, 12    # t4=0xf~f used for not operation (by xor)
    ### nor operation 
    or t5, t1, zero
    xor t5, t4, t5    # nor t5, t1, zero    (t5 = ~(t1 | zero))
    bgeu t5, t3, 8    # if no overflow then jump
    addi t0, t0, 1    # if overflow upper bits plus 1

    # x += ((x>>4)+x) & 0x0f~0f
    lui t4, 0x0f0f0
    srli t5, t4, 16
    or t4, t4, t5    # t4=0x0f~0f
    srli    t3, t1, 4
    slli    t2, t0, 28
    or      t3, t3, t2
    srli    t2, t0, 4    # [t2, t3] = x>>4   
    ## (x>>4) + x
    add t1, t1, t3
    add t0, t0, t2
    ### overflow detection
    lui t5, 0xfffff
    srai t5, t5, 12    # t5=0xf~f used for not operation (by xor)
    #### nor operation
    or t6, t1, zero
    xor t6, t5, t6    # nor a4, t1, zero    (a4 = ~(t1 | zero))
    bgeu t6, t3, 8
    addi t0, t0, 1
    ## ((x>>4) + x) & 0x0f~0f
    and t0, t0, t4
    and t1, t1, t4
    
    # x += x(x>>8)
    srli    t3, t1, 8
    slli    t2, t0, 24
    or      t3, t3, t2
    srli    t2, t0, 8    # [t2, t3] = x>>8 
    add     t0, t0, t2
    add     t1, t1, t3
    ## overflow detection
    lui     t4, 0xfffff
    srai    t5, t5, 12
    ### nor operation
    or      t5, t1, zero
    xor     t5, t4, t5
    bgeu    t5, t3, 8
    addi t0, t0, 1
    
    # x += x(x>>16)
    srli    t3, t1, 16
    slli    t2, t0, 16
    or      t3, t3, t2
    srli    t2, t0, 16    # [t2, t3] = x>>8 
    add     t0, t0, t2
    add     t1, t1, t3
    ## overflow detection
    lui     t4, 0xfffff
    srai    t5, t5, 12
    ### nor operation
    or      t5, t1, zero
    xor     t5, t4, t5
    bgeu    t5, t3, 8
    addi t0, t0, 1
    
    # x += (x>>32)
    add     t3, t0, zero
    add     t2, zero, zero
    add     t0, t0, t2
    add     t1, t1, t3
    ## overflow detection
    lui     t4, 0xfffff
    srai    t5, t5, 12
    ### nor operation
    or      t5, t1, zero
    xor     t5, t4, t5
    bgeu    t5, t3, 8
    addi t0, t0, 1
    
    # 64 - (x & (0x7f))
    addi    t4, zero, 0x7f
    addi    a0, zero, 64
    and      t1, t1, t4
    sub     a0, a0, t1
    lw    ra, 0(sp)
    sw     a0, 0(sp)
    jalr    ra
 End:
     add   zero, zero, zero  
    
    
    
    
    
    
    
    

    
    

    
    
    