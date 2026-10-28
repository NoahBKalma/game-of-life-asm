.data
    alive: .byte 0xE2, 0x96, 0x88, 0xE2, 0x96, 0x88     // 6 bytes for alive square
    dead: .ascii "  "                                   // 2 bytes for dead square, 0x20
    newline: .ascii "\n"                                // 0x0A
    sleep_time: .quad 0, 500000000                      // 0 seconds, 500,000,000 ns = 0.5 s

.bss
    calc_grid_buffer: .space 420                             // 20x20 grid with a newline character at the end of each row
    new_grid_buffer: .space 420                             // new grid
//  index = r * 21 + c        with c from 0 to 20
//  add/subtract 21 to go up/down a row, add, subtract 1 to go left/right

.text
.global _start

/* ----- Registers ------

    x19 = calc grid buffer
    x20 = next frame grid buffer
    w12 = changed for whatever constant is needed
    w13 = changed for whatever constant is needed

    CALC_STEP
    w9 = live neighbor count
    w11 = loop counter
    w15 = main loop counter

*/

_start:	
    ldr x19, =calc_grid_buffer  
    ldr x20, =new_grid_buffer

    mov x0, x19                     // argument for FILL_GRID_ZEROS
    bl FILL_GRID_ZEROS
    mov x0, x20                     // initialize new grid with zeros
    bl FILL_GRID_ZEROS
    
    mov w12, #0x31                  // 1
    strb w12, [x19, #24]            // write 1s at every corner
    strb w12, [x19, #46]            // write 1s at every corner
    strb w12, [x19, #67]            // write 1s at every corner
    strb w12, [x19, #66]            // write 1s at every corner
    strb w12, [x19, #65]            // write 1s at every corner
    

    mov w15, wzr
MAIN_LOOP:
    cmp w15, #8
    b.gt 99f

    mov x1, x19                     // print grid argument
    bl PRINT_GRID

    bl CALC_STEP
    bl SLEEP
    mov x19, x20                    // set the past grid to the new grid

    add w15, w15, #1
    b MAIN_LOOP
    
99:
	mov x8, #0x5D                   // exit syscall
	mov x0, #0
    svc #0

/* --------------- FUNCTIONS -------------- */

FILL_GRID_ZEROS:
// Parameters: x0 for grid buffer

    mov w11, #0             // loop counter
    mov x10, #21           // constant to make grid 20 columns
FILL_ZEROS_LOOP:
    cmp w11, #420
    b.ge 99f

    udiv x13, x11, x10
    msub x3, x13, x10, x11
    cmp x3, #20
    b.ne 2f

1:
    mov w12, #0x0A      // newline
    strb w12, [x0, x11]
    b 3f
2:
    mov w12, #0x30      // 0
    strb w12, [x0, x11]
3:
    add w11, w11, #1
    b FILL_ZEROS_LOOP

99:
    ret

PRINT_GRID:
// Parameters: x1 for grid buffer

    mov x8, #0x40                   // write syscall
    mov x0, #1
    mov x2, #420
    svc #0

    ret


CALC_STEP:
    // need to loop through columns 1-18 (skip the first, last, and newline) and rows 1-19 too
    // reference lines 31-34 for corners
    // points should be, when modded by 21, between 1 and 18 inclusive
    // exclude anything <22 and >396
    mov w11, #22

CALC_LOOP:
    mov w9, wzr                 // count of live neighbors
    cmp w11, #396
    b.gt 99f
    
    sub w12, w11, #22            // offset of neighbor up and left
    ldrb w10, [x19, x12]         // puts the value of a neighbor in w10, cycles through all neighbors
    cmp w10, #0x31
    cinc w9, w9, eq

    sub w12, w11, #21            // offset of neighbor up
    ldrb w10, [x19, x12]
    cmp w10, #0x31
    cinc w9, w9, eq

    sub w12, w11, #20            // offset of neighbor up and right
    ldrb w10, [x19, x12]
    cmp w10, #0x31
    cinc w9, w9, eq

    sub w12, w11, #1            // offset of neighbor left
    ldrb w10, [x19, x12]
    cmp w10, #0x31
    cinc w9, w9, eq

    add w12, w11, #1            // offset of neighbor right
    ldrb w10, [x19, x12]
    cmp w10, #0x31
    cinc w9, w9, eq

    add w12, w11, #20            // offset of neighbor down and left
    ldrb w10, [x19, x12]
    cmp w10, #0x31
    cinc w9, w9, eq

    add w12, w11, #21            // offset of neighbor down
    ldrb w10, [x19, x12]
    cmp w10, #0x31
    cinc w9, w9, eq

    add w12, w11, #22            // offset of neighbor down and right
    ldrb w10, [x19, x12]
    cmp w10, #0x31
    cinc w9, w9, eq

    // now w9 has the full live neighbor count
    // x20 is the grid to edit, x11 is current place
    mov w12, #0x30
    mov w13, #0x31

    ldrb w10, [x19, x11]        // current cell
    
    cmp w10, #0x31              // BRANCH FOR CURRENT CELL DEAD
    b.eq 1f
    cmp w9, #3
    cinc w10, w10, eq           // make the cell alive in new grid
    strb w10, [x20, x11]
    b 98f

1:                              // BRANCH FOR CURRENT CELL ALIVE
    cmp w9, #1
    b.gt 2f                     // ALL WITH <= 1 neighbors die
    sub w10, w10, #1            // make the cell dead in new grid
    strb w10, [x20, x11]
    b 98f

2:                          
    cmp w9, #3
    b.gt 3f                     // ALL WITH 1 < neighbors <= 3 survive
    strb w10, [x20, x11]
    b 98f

3:                               // ALL WITH >= 4 neighbors die
    sub w10, w10, #1             // make the cell dead in new grid
    strb w10, [x20, x11]
    b 98f

98:
    add w11, w11, #1
    mov w14, #21                // skip the border columns
    udiv w15, w11, w14
    msub w13, w15, w14, w11     // w13 = column of the next cell (index mod 21)
    cmp w13, #19                // column 19 is the right border
    b.ne CALC_LOOP
    add w11, w11, #3            // jump from column 19 to column 1 of the next row
    b CALC_LOOP

99:
    ret

SLEEP:
    mov x8, #0x65               // nanosleep syscall
    ldr x0, =sleep_time
    mov x1, #0                  // no pointer for the remaining time
    svc #0
    ret
