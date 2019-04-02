# BFASM
Brainfuck interpreter for Linux, written in IA-32 assembly language using the NASM syntax.

---

## Version
Current version: **2019.04.0**

*The version format is &quot;&lt;year&gt;.&lt;zero padded month&gt;.&lt;revision number&gt;&quot;.*

---

## Brainfuck
Brainfuck is a very simple programming language created by Urban Müller in 1993. It has 8 different instructions, which are used to operate an array of memory cells and a cell pointer, and it is a turing complete language. The minimalism of the language means that it is very complex to create anything useful with it.

### Instructions

Instruction | Description | C equivalent
:---:|---|---
\> | increase cell pointer | ++cellPointer;
\> | decrease cell pointer | --cellPointer;
\+ | increase cell value | ++\*cellPointer;
\- | decrease cell value | --\*cellPointer;
. | print cell value | putchar(\*cellPointer);
, | store one byte of input into cell | \*cellPointer = getchar();
\[ | if the cell value is 0, jump to the instruction next to the matching '\]' | while (\*cellPointer == 0) {
\] | if the cell value is not 0, jump to the instruction next to the matching '\[' | }

---

## Specifications

Description | Value
---|---
Cell size | 1 byte
Tape size | 30000 cells (configurable)
Out of bounds behaviour | wraparound
New line value | 10
EOF behaviour | no change
Input stream | standard input
Output stream | standard output
Error stream | standard error

## Usage

This program uses the NASM syntax, so it needs to be assembled using the NASM assembler.

Assembly:
```
nasm -f elf main.asm
ld -m elf_i386 -s -o bfasm main.o
```

Usage:

```
./bfasm <file name> [tape size]
```

---

## Limitations

+ Fixed size cells
+ ASCII only input files
+ Slow implementation

---

## Possible future changes

+ Faster bracket jumps

---

## Notes

This interpreter was created for learning purposes and it's not meant to be used for anything serious.