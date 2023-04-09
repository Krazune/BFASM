# BFASM
Brainfuck interpreter for Linux, written in _IA-32/i386/x86_ assembly language using the NASM syntax.

![Mandelbrot](resources/mandelbrot.gif)

*Execution of the mandelbrot program by Erik Bosman.*

---

## Version
Current version: **2019.04.1**

Format: *\<year\>.\<zero padded month\>.\<revision number\>*

---

## License

[MIT License](https://github.com/Krazune/BFASM/blob/master/LICENSE.md)

---

## Brainfuck
Brainfuck is a very simple programming language created by Urban Müller in 1993. It has 8 different instructions which are used to operate a pointer, and an array of memory cells. The minimalistic aspect of the language means that it is very complex to create anything useful with it. Despite its simplicity, it's still a turing complete language.

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

This program needs to be assembled using the NASM assembler.

### Assembly:
```
nasm -f elf main.asm
ld -m elf_i386 -s -o bfasm main.o
```

### Usage:
```
./bfasm <file name> [tape size]
```

### Dockerfile:
A dockerfile is included which takes the same amount of arguments as bfasm, but the bf code must be passed directly as an argument.
```
docker build -t bfasm .
docker run --rm -it bfasm <bf program surrounded by quotes> [tape size]
```

Docker run example:
```
docker run --rm -it bfasm ">++++++++++++++[<+++++++>-]<.++++."
```

---

## Limitations

+ Fixed size cells
+ ASCII only input files
+ Slow implementation (slow bracket jumps)