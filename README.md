# Game of Life in AArch64 Assembly

Conway's Game of Life in the terminal, written in AArch64 Linux assembly. It uses raw syscalls only, with no libc. The grid is 40 by 40 and each generation is drawn with block characters.

## Build and run

Requires an AArch64 Linux machine (or VM) with the GNU toolchain. The terminal should be at least 80 columns wide and 41 rows tall.

```sh
as -o game-of-life.o game-of-life.s
ld -o game-of-life game-of-life.o
./game-of-life        # default preset (1)
./game-of-life 6      # pick a preset by number
```

## Presets

Pass a number from 1 to 9 as the first argument.

| # | Pattern | Behavior |
|---|---------|----------|
| 1 | Acorn | 7 cells that grow into a large, chaotic colony |
| 2 | Gosper glider gun | Fires a glider every 30 generations |
| 3 | R-pentomino | 5 cells that explode into chaos |
| 4 | Pulsar | Period 3 oscillator |
| 5 | Octagon ring | Period 5 oscillator |
| 6 | Figure eight | Period 8 oscillator |
| 7 | Kok's galaxy | Period 8 oscillator |
| 8 | Tumbler | Period 14 oscillator |
| 9 | Pentadecathlon | Period 15 oscillator |

## How it works

- **Grid:** One byte per cell (`'0'` or `'1'`), 41 bytes per row (40 cells plus a newline). The outer ring is always dead, so the playable area is 38 by 38 and neighbor counting needs no bounds checks.
- **Step:** Each playable cell's 8 neighbors are counted and the result is written into a second grid. The two grid pointers are then swapped instead of copied.
- **Render:** Each frame is built in one buffer (`██` for alive, two spaces for dead) that starts with the ANSI cursor-home sequence, so a single `write` redraws the screen without flicker.
- **Presets:** Starting grids are stored in `.data`, and the preset number is read from `argv[1]`.

## Key registers

| Register | Purpose |
|----------|---------|
| x19 | current grid buffer |
| x20 | next grid buffer |
| w21 | frame counter |
| x8 | syscall number |
| x0, x1, x2 | syscall arguments |

Scratch registers used inside each function are documented in the comment block at the top of `game-of-life.s`.

## Notes

- Cells outside the border are treated as dead, so patterns that reach a wall behave differently than on an infinite grid.
- Syscalls used: `write` (0x40), `nanosleep` (0x65), and `exit` (0x5D).