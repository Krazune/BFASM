%ifndef INTERPRETER_ASM
%define INTERPRETER_ASM

%include "system.asm"

NO_ERROR		equ	0
GENERAL_ERROR	equ	1

TAPE_SIZE		equ	30000

segment .data
	leftBracketError		db	'No matching right bracket.', 0xA, 0
	leftBracketErrorLength	equ	$ - leftBracketError

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
	call	decrementCellValue
	jmp		interprete.readingLoop

.dot:
	call	printValue
	jmp		interprete.readingLoop

.comma:
	call	getValue
	jmp		interprete.readingLoop

.leftBracket:
	call	jumpForwards

	cmp		eax, 0
	jne		interprete.readingLoop

	call	printLeftBracketError
	jmp		interprete.failure

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

decrementCellValue:
	enter	0, 0

	mov		eax, dword [cellIndex]
	dec		byte [eax + tape]

	leave
	ret

printValue:
	enter	0, 0

	mov		eax, tape
	add		eax, dword [cellIndex]

	push	1
	push	eax
	push	STDOUT
	call	sysWrite
	add		esp, 12

	leave
	ret

getValue:
	enter	0, 0

	mov		eax, tape
	add		eax, dword [cellIndex]

	push	1
	push	eax
	push	STDIN
	call	sysRead
	add		esp, 12

	leave
	ret

jumpForwards:
	enter	8, 0

;	mov		eax, tape
;	add		eax, dword [cellIndex]

	mov		eax, dword [cellIndex]

	cmp		byte [eax + tape], 0
	jne		jumpForwards.success

	mov		dword [ebp - 8], 1

.readingLoop:
	push	1
	lea		eax, [ebp - 4]
	push	eax
	push	dword [inputFileDescriptor]
	call	sysRead
	add		esp, 12

	cmp		eax, 0 ; not working properly
	je		jumpForwards.error

	cmp		byte [ebp - 4], '['
	je		jumpForwards.leftBracket

	cmp		byte [ebp - 4], ']'
	je		jumpForwards.rightBracket

	jmp		jumpForwards.readingLoop

.leftBracket:
	inc		dword [ebp - 8]
	jmp		jumpForwards.readingLoop

.rightBracket:
	dec		dword [ebp - 8]

	cmp		dword [ebp - 8], 0
	jne		jumpForwards.readingLoop

	jmp		jumpForwards.success

.error:
	mov		eax, 0
	jmp		jumpForwards.exit

.success:
	mov		eax, 1 ;
	jmp		jumpForwards.exit

.exit:
	leave
	ret

printLeftBracketError:
	enter	0, 0

	push	leftBracketErrorLength
	push	leftBracketError
	push	STDERR
	call	sysWrite
	add		esp, 12

	leave
	ret

%endif