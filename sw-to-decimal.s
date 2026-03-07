.text
.global _start

_start:
    movia   r2, 0xff200020      # HEX3-HEX0
    movia   r3, 0xff200030      # HEX5-HEX4
    movia   r4, 0xff200040      # switches
    movia   r5, DIGITS          # 7-seg digit table

MAIN_LOOP:
    # Read 10-bit switch value
    ldwio   r6, 0(r4)
    andi    r6, r6, 0x03FF      # keep only 10 bits (0-1023)

    # r6 = number
    # Find thousands digit -> r7
    mov     r8, r6              # working copy
    movi    r7, 0               # thousands = 0

THOUSANDS_LOOP:
    movi    r9, 1000
    blt     r8, r9, HUNDREDS_START
    subi    r8, r8, 1000
    addi    r7, r7, 1
    br      THOUSANDS_LOOP

HUNDREDS_START:
    movi    r10, 0              # hundreds = 0

HUNDREDS_LOOP:
    movi    r9, 100
    blt     r8, r9, TENS_START
    subi    r8, r8, 100
    addi    r10, r10, 1
    br      HUNDREDS_LOOP

TENS_START:
    movi    r11, 0              # tens = 0

TENS_LOOP:
    movi    r9, 10
    blt     r8, r9, ONES_READY
    subi    r8, r8, 10
    addi    r11, r11, 1
    br      TENS_LOOP

ONES_READY:
    # digits:
    # r7  = thousands
    # r10 = hundreds
    # r11 = tens
    # r8  = ones

    # ----------------------------
    # Load segment patterns
    # ----------------------------

    # ones -> r12
    add     r13, r5, r8
    ldb     r12, 0(r13)

    # tens -> r14
    add     r13, r5, r11
    ldb     r14, 0(r13)

    # hundreds -> r15
    add     r13, r5, r10
    ldb     r15, 0(r13)

    # thousands -> r16
    add     r13, r5, r7
    ldb     r16, 0(r13)

    # blank pattern
    movi    r17, 0x00

    # ----------------------------
    # Optional leading-zero blanking
    # ----------------------------

    # If thousands == 0, blank HEX3
    beq     r7, r0, BLANK_THOUSANDS
    br      CHECK_HUNDREDS

BLANK_THOUSANDS:
    mov     r16, r17

CHECK_HUNDREDS:
    # If thousands == 0 and hundreds == 0, blank HEX2
    bne     r7, r0, KEEP_HUNDREDS
    bne     r10, r0, KEEP_HUNDREDS
    mov     r15, r17

KEEP_HUNDREDS:
    # If thousands == 0 and hundreds == 0 and tens == 0, blank HEX1
    bne     r7, r0, KEEP_TENS
    bne     r10, r0, KEEP_TENS
    bne     r11, r0, KEEP_TENS
    mov     r14, r17

KEEP_TENS:
    # HEX0 always shows ones

    # ----------------------------
    # Build HEX3-HEX0 word
    # HEX3 = thousands
    # HEX2 = hundreds
    # HEX1 = tens
    # HEX0 = ones
    # ----------------------------
    slli    r16, r16, 24
    slli    r15, r15, 16
    slli    r14, r14, 8

    or      r18, r16, r15
    or      r18, r18, r14
    or      r18, r18, r12

    # ----------------------------
    # Build HEX5-HEX4 word
    # both blank because max is 1023
    # ----------------------------
    movi    r19, 0x0000

    # Write displays
    stwio   r18, 0(r2)          # HEX3-HEX0
    stwio   r19, 0(r3)          # HEX5-HEX4

    br      MAIN_LOOP


.data
DIGITS:
    .byte   0b00111111          # 0
    .byte   0b00000110          # 1
    .byte   0b01011011          # 2
    .byte   0b01001111          # 3
    .byte   0b01100110          # 4
    .byte   0b01101101          # 5
    .byte   0b01111101          # 6
    .byte   0b00000111          # 7
    .byte   0b01111111          # 8
    .byte   0b01100111          # 9
