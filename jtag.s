.global _start
_start:


    movia r2, 0xff201000      # JTAG UART base address
    movi  r20, 0              # running total initialized to 0
	
program_loop:
    movia r15, STR_PROMPT
	
print_prompt:
    ldb   r16, 0(r15)
    beq   r16, r0, await_input
    addi  r15, r15, 1
    call  uart_send
    br    print_prompt
	
await_input:
    movi  r5, 0               # reset current number
	
read_loop:

wait_char:
    ldwio r17, 0(r2)          # read UART data register
    andi  r18, r17, 0x8000    # check RVALID bit
    beq   r18, r0, wait_char  # wait until character arrives
    andi  r16, r17, 0xFF      # extract ASCII character
    mov   r23, r16            # save character before uart_send clobbers r17
    call  uart_send           # echo typed character
    mov   r16, r23            # restore character after echo
    movi  r19, 0x0A
    beq   r16, r19, accumulate
    movi  r19, 0x0D
    beq   r16, r19, accumulate
    movi  r19, 0x30
    blt   r16, r19, read_loop
    movi  r19, 0x39
    bgt   r16, r19, read_loop
    addi  r16, r16, -48       # convert ASCII digit to integer
    movi  r19, 10
    mul   r5, r5, r19         # shift number left one decimal place
    add   r5, r5, r16         # add new digit
	
    br    read_loop
	
accumulate:

    add   r20, r20, r5        # add number to running total
    movia r15, STR_TOTAL
	
print_total:
    ldb   r16, 0(r15)
    beq   r16, r0, print_digits
    addi  r15, r15, 1
    call  uart_send
    br    print_total
	
print_digits:

    # extract all digits first, store in r12-r15
    mov   r5, r20
    movi  r6, 10
    div   r7, r5, r6
    mul   r8, r7, r6
    sub   r12, r5, r8         # ones digit
    div   r9, r7, r6
    mul   r8, r9, r6
    sub   r13, r7, r8         # tens digit
    div   r10, r9, r6
    mul   r8, r10, r6
    sub   r14, r9, r8         # hundreds digit
    mov   r15, r10            # thousands digit
    # convert all digits to ASCII before any printing
    addi  r12, r12, 48
    addi  r13, r13, 48
    addi  r14, r14, 48
    addi  r15, r15, 48
    # suppress leading zeros, r17/r8 no longer needed so uart_send is safe
    movi  r22, 48             # ASCII '0' for comparison
    beq   r15, r22, hide_thousands
    mov   r16, r15
    call  uart_send
	
hide_thousands:

    bne   r15, r22, show_hundreds
    beq   r14, r22, hide_hundreds
	
show_hundreds:
    mov   r16, r14
    call  uart_send
	
hide_hundreds:
    bne   r15, r22, show_tens
    bne   r14, r22, show_tens
    beq   r13, r22, hide_tens
	
show_tens:
    mov   r16, r13
    call  uart_send
	
hide_tens:
    # ones digit always printed
    mov   r16, r12
    call  uart_send
    movi  r16, 0x0A
    call  uart_send
    br    program_loop
	
uart_send:
wait_uart:

    ldwio r17, 4(r2)          # read control register
    srli  r17, r17, 16        # extract write space
    beq   r17, r0, wait_uart  # wait if buffer full
    stwio r16, 0(r2)          # write character
    ret
	
	
.data
STR_PROMPT: .string "Enter number:"
STR_TOTAL:  .string "Total:"
