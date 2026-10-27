.data
    alive: .byte 0xE2, 0x96, 0x88, 0xE2, 0x96, 0x88     // 6 bytes for alive square
    dead: .ascii "  "                                   // 2 bytes for dead square, 0x20
    newline: .ascii "\n"                                // 0x0A

.bss
    calc_buffer: .space 420                             // 20x20 grid with a newline character at the end of each row
//  index = r * 21 + c        with c from 0 to 20


.text
.global _start

_start:	
    bl FILL_CALC_GRID
    bl PRINT_CALC_GRID

99:
	mov x8, #0x5D                   // exit syscall
	mov x0, #0
    svc #0

/* ----- FUNCTIONS ----- */

FILL_CALC_GRID:
 mov x9, #0             // loop counter
    mov x10, #21           // constant to make grid 20 columns
    ldr x11, =calc_buffer
LOOP:
    cmp x9, #420
    b.ge 99f

    udiv x13, x9, x10
    msub x3, x13, x10, x9
    cmp x3, #20
    b.ne 2f

1:
    mov w12, #0x0A
    strb w12, [x11, x9]
    b 3f
2:
    mov w12, #0x31
    strb w12, [x11, x9]
3:
    add x9, x9, #1
    b LOOP

99:
    ret

PRINT_CALC_GRID:

    mov x8, #0x40                   // write syscall
    mov x0, #1
    ldr x1, =calc_buffer
    mov x2, #420
    svc #0

    ret

