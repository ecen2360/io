.text
.global _start

_start:
    movia   r2, 0xff200020      # HEX0-HEX3
    movia   r18, 0xff200030     # HEX4-HEX5
    movia   r3, 0xff200040      # switches
    movia   r4, NUMS            # 7-seg lookup table

function:

    ldwio   r5, 0(r3)           # read switch value

    movi    r6, 10

    # Ones digit 
    div     r7, r5, r6          # r7 = n/10
    mul     r8, r7, r6
    sub     r12, r5, r8         # r12 = ones

    # Tens digit
    div     r9, r7, r6          # r9 = n/100
    mul     r8, r9, r6
    sub     r14, r7, r8         # r14 = tens

    # Hundreds digit 
    div     r10, r9, r6         # r10 = n/1000
    mul     r8, r10, r6
    sub     r16, r9, r8         # r16 = hundreds

    # Thousands digit 
    mov     r13, r10            # r13 = thousands

    # Lookup 7-seg 
    add     r12, r4, r12
    ldbu    r12, 0(r12)

    add     r14, r4, r14
    ldbu    r14, 0(r14)

    add     r16, r4, r16
    ldbu    r16, 0(r16)

    add     r13, r4, r13
    ldbu    r13, 0(r13)

    # HEX0-HEX3 
    slli    r14, r14, 8         # HEX1
    slli    r16, r16, 16        # HEX2
    slli    r13, r13, 24        # HEX3

    or      r17, r12, r14
    or      r17, r17, r16
    or      r17, r17, r13

    stwio   r17, 0(r2)

    # Clear
    movi    r17, 0
    stwio   r17, 0(r18)

    br      function


.data

NUMS:
    .byte   0b00111111   # 0
    .byte   0b00000110   # 1
    .byte   0b01011011   # 2
    .byte   0b01001111   # 3
    .byte   0b01100110   # 4
    .byte   0b01101101   # 5
    .byte   0b01111101   # 6
    .byte   0b00000111   # 7
    .byte   0b01111111   # 8
    .byte   0b01101111   # 9
