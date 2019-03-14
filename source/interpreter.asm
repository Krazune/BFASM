%ifndef INTERPRETER_ASM
%define INTERPRETER_ASM

%include "system.asm"

NO_ERROR		equ	0
GENERAL_ERROR	equ	1

TAPE_SIZE		equ	30000

segment .data
	tape			times TAPE_SIZE db	0
	cellIndex		dd	0

segment .bss
	inputFileDescriptor	resd	1

segment .text
interprete:
	enter	4, 0

	push	0777
	push	RDONLY
	push	dword [ebp + 8]	; Input file path
	call	sysOpen			; Open file
	add		esp, 12

	cmp		eax, 0				; Check if file was open successfully
	jl		interprete.failure

	mov		[inputFileDescriptor], eax	; Store file descriptor

	; Interprete file
.readingLoop:
	push	1
	lea		eax, [ebp - 4]
	push	eax
	push	dword [inputFileDescriptor]
	call	sysRead
	add		esp, 12

	cmp		eax, 0
	je		interprete.success

	cmp		byte [ebp - 4], '>'
	je		interprete.greaterThan

	cmp		byte [ebp - 4], '<'
	je		interprete.lessThan

	cmp		byte [ebp - 4], '+'
	je		interprete.plus

	cmp		byte [ebp - 4], '-'
	je		interprete.minus

	cmp		byte [ebp - 4], '.'
	je		interprete.dot

	cmp		byte [ebp - 4], ','
	je		interprete.comma

	cmp		byte [ebp - 4], '['
	je		interprete.leftBracket

	cmp		byte [ebp - 4], ']'
	je		interprete.rightBracket

	jmp interprete.readingLoop

.greaterThan:
	call	incrementCellIndex
	jmp		interprete.readingLoop

.lessThan:
	call	decrementCellIndex
	jmp		interprete.readingLoop

.plus:
	call	incrementCellValue
	jmp		interprete.readingLoop

.minus:
	; interprete -
	jmp		interprete.readingLoop

.dot:
	; interprete .
	jmp		interprete.readingLoop

.comma:
	; interprete ,
	jmp		interprete.readingLoop

.leftBracket:
	; interprete [
	jmp		interprete.readingLoop

.rightBracket:
	; interprete ]
	jmp		interprete.readingLoop

.failure:
	mov		eax, GENERAL_ERROR
	jmp		interprete.exit

.success:
	push	dword [inputFileDescriptor]
	call	sysClose
	add		esp, 4

	mov		eax, NO_ERROR
	jmp		interprete.exit

.exit:
	leave
	ret

incrementCellIndex:
	enter	0, 0

	inc		dword [cellIndex]

	cmp		dword [cellIndex], TAPE_SIZE	; Check for wraping
	jl		incrementCellIndex.exit

	mov		dword [cellIndex], 0			; Wrap around to 0

.exit:
	leave
	ret

decrementCellIndex:
	enter	0, 0

	dec		dword [cellIndex]

	cmp		dword [cellIndex], 0				; Check for wraping
	jge		incrementCellIndex.exit

	mov		dword [cellIndex], TAPE_SIZE - 1	; Wrap around to last cell

.exit:
	leave
	ret

incrementCellValue:
	enter	0, 0

	mov		eax, dword [cellIndex]
	inc		byte [eax + tape]

	leave
	ret

%endif