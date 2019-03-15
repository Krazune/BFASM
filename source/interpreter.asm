%ifndef INTERPRETER_ASM
%define INTERPRETER_ASM



%include "system.asm"



NO_ERROR		equ	0
GENERAL_ERROR	equ	1

TAPE_SIZE		equ	30000



segment .data
	leftBracketError		db	'No matching right bracket.', 0xA, 0
	leftBracketErrorLength	equ	$ - leftBracketError

	rightBracketError		db	'No matching left bracket.', 0xA, 0
	rightBracketErrorLength	equ	$ - rightBracketError

	tape			times TAPE_SIZE db	0
	cellIndex		dd	0



segment .bss
	inputFileDescriptor	resd	1



segment .text
interprete:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer
	sub		esp, 4						; Reserve 4 bytes on the stack for a local variable (current character)

	push	0							; Mode is ignored on read only
	push	RDONLY
	push	dword [ebp + 8]				; File path received as argument
	call	sysOpen						; Open file
	add		esp, 12						; Clear stack arguments

	cmp		eax, 0						; Check if the file was open successfully
	jl		interprete.failure			; Exit the procedure if the file was not open successfully

	mov		[inputFileDescriptor], eax	; Store file descriptor

.readingLoop:
	lea		eax, [ebp - 4]				; Store the current character's local variable effective address in register eax
	push	1
	push	eax
	push	dword [inputFileDescriptor]
	call	sysRead						; Read a single byte from the file
	add		esp, 12						; Clear stack arguments

	cmp		eax, 0						; Check if the read operation read any byte
	je		interprete.success			; Exit the procedure successfully when no bytes are left to be read

	cmp		byte [ebp - 4], '>'			; Check if the character read is '>'
	je		interprete.greaterThan		; Process the '>' symbol

	cmp		byte [ebp - 4], '<'			; Check if the character read is '<'
	je		interprete.lessThan			; Process the '<' symbol

	cmp		byte [ebp - 4], '+'			; Check if the character read is '+'
	je		interprete.plus				; Process the '+' symbol

	cmp		byte [ebp - 4], '-'			; Check if the character read is '-'
	je		interprete.minus			; Process the '-' symbol

	cmp		byte [ebp - 4], '.'			; Check if the character read is '.'
	je		interprete.dot				; Process the '.' symbol

	cmp		byte [ebp - 4], ','			; Check if the character read is ','
	je		interprete.comma			; Process the ',' symbol

	cmp		byte [ebp - 4], '['			; Check if the character read is '['
	je		interprete.leftBracket		; Process the '[' symbol

	cmp		byte [ebp - 4], ']'			; Check if the character read is ']'
	je		interprete.rightBracket		; Process the ']' symbol

	jmp interprete.readingLoop			; Ignore the character read if it's not a valid symbol

.greaterThan:
	call	incrementCellIndex			; Increment the cell index
	jmp		interprete.readingLoop		; Keep reading the file

.lessThan:
	call	decrementCellIndex			; Decrement the cell index
	jmp		interprete.readingLoop		; Keep reading the file

.plus:
	call	incrementCellValue			; Increment the cell value
	jmp		interprete.readingLoop		; Keep reading the file

.minus:
	call	decrementCellValue			; Decrement the cell value
	jmp		interprete.readingLoop		; Keep reading the file

.dot:
	call	printValue					; Print the cell value
	jmp		interprete.readingLoop		; Keep reading the file

.comma:
	call	getValue					; Store a single byte of input into the cell value at index
	jmp		interprete.readingLoop		; Keep reading the file

.leftBracket:
	call	jumpForwards				; Jump forward to the instruction after the matching ']' symbol if the current cell value is 0

	cmp		eax, 0						; Check if any error occurred when jumping forward (missing matching bracket)
	jne		interprete.readingLoop		; Keep reading the file if no error was found

	call	printLeftBracketError		; Print the missing bracket error
	jmp		interprete.failure			; Exit the procedure with a failure return value

.rightBracket:
	call	jumpBackwards				; Jump backwards to the instruction after the matching '[' symbol if the current cell value is not 0

	cmp		eax, 0						; Check if any error occurred when jumping backwards (missing matching bracket)
	jne		interprete.readingLoop		; Keep reading the file if no error was found

	call	printRightBracketError		; Print the missing bracket error
	jmp		interprete.failure			; Exit the procedure with a failure return value

.failure:
	mov		eax, GENERAL_ERROR			; Set the failure return value
	jmp		interprete.exit				; Exit the procedure

.success:
	push	dword [inputFileDescriptor]
	call	sysClose					; Close the open file descriptor
	add		esp, 4						; Clear stack arguments

	mov		eax, NO_ERROR				; Set the success return value
	jmp		interprete.exit				; Exit the procedure

.exit:
	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller



incrementCellIndex:
	push	ebp								; Store base pointer
	mov		ebp, esp						; Set base pointer to stack pointer

	inc		dword [cellIndex]				; Increment cell index

	cmp		dword [cellIndex], TAPE_SIZE	; Check if the index is out of the tape bounds
	jl		incrementCellIndex.exit			; Exit procedure if the index is not out of bounds

	mov		dword [cellIndex], 0			; Wrap index back to the first cell

.exit:
	mov		esp, ebp						; Clear stack
	pop		ebp								; Restore base pointer
	ret										; Return to caller



decrementCellIndex:
	push	ebp									; Store base pointer
	mov		ebp, esp							; Set base pointer to stack pointer

	dec		dword [cellIndex]					; Decrement cell index

	cmp		dword [cellIndex], 0				; Check if the index is out of the tape bounds
	jge		incrementCellIndex.exit				; Exit procedure if the index is not out of bounds

	mov		dword [cellIndex], TAPE_SIZE - 1	; Wrap around to the last cell

.exit:
	mov		esp, ebp							; Clear stack
	pop		ebp									; Restore base pointer
	ret											; Return to caller



incrementCellValue:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	mov		eax, dword [cellIndex]	; Load cell index into the register eax
	inc		byte [eax + tape]		; Increment cell value at the index

	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller



decrementCellValue:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	mov		eax, dword [cellIndex]	; Load cell index into the register eax
	dec		byte [eax + tape]		; Decrement cell value at the index

	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller



printValue:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	mov		eax, tape				; Load tape address into register eax
	add		eax, dword [cellIndex]	; Add cell index offset to the tape address

	push	1
	push	eax
	push	STDOUT
	call	sysWrite				; Print cell value at index
	add		esp, 12					; Clear stack arguments

	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller



getValue:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	mov		eax, tape				; Load tape address into register eax
	add		eax, dword [cellIndex]	; Add cell index offset to the tape address

	push	1
	push	eax
	push	STDIN
	call	sysRead					; Store input into the cell at index
	add		esp, 12					; Clear stack arguments

	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller



jumpForwards:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer
	sub		esp, 8						; Reserve 8 bytes on the stack for local variables (current character, and nesting level)

	mov		eax, dword [cellIndex]		; Load cell index into the register eax

	cmp		byte [eax + tape], 0		; Check if value at cell index is 0
	jne		jumpForwards.success		; If the cell value is not 0 leave procedure successfully

	mov		dword [ebp - 8], 1			; Set the local variable nesting level to 1

.readingLoop:
	lea		eax, [ebp - 4]				; Store the nesting level's local variable effective address in register eax
	push	1
	push	eax
	push	dword [inputFileDescriptor]
	call	sysRead						; Read a single byte from the file
	add		esp, 12						; Clear stack arguments

	cmp		eax, 0						; Check if the read operation read any byte
	je		jumpForwards.error			; Exit the procedure unsuccessfully when no bytes are left to be read

	cmp		byte [ebp - 4], '['			; Check if the character read is '['
	je		jumpForwards.leftBracket	; Increase the nesting level if the character read is '['

	cmp		byte [ebp - 4], ']'			; Check if the character read is ']'
	je		jumpForwards.rightBracket	; Decrease the nesting level if the character read is ']', and check if it's the matching bracket

	jmp		jumpForwards.readingLoop	; Keep reading the file

.leftBracket:
	inc		dword [ebp - 8]				; Increment the nesting level
	jmp		jumpForwards.readingLoop	; Keep reading the file

.rightBracket:
	dec		dword [ebp - 8]				; Decrement the nesting level

	cmp		dword [ebp - 8], 0			; Check if the nesting level is 0
	jne		jumpForwards.readingLoop	; If the nesting level is not 0, the matching bracket was not found, keep reading the file

	jmp		jumpForwards.success		; If the nesting level is 0 exit the procedure successfully

.error:
	mov		eax, 0						; Set the failure return value
	jmp		jumpForwards.exit			; Exit the procedure

.success:
	mov		eax, 1						; Set the successfully return value
	jmp		jumpForwards.exit			; Exit the procedure

.exit:
	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller



jumpBackwards:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer
	sub		esp, 8						; Reserve 8 bytes on the stack for local variables (current character, and nesting level)

	mov		eax, dword [cellIndex]		; Load cell index into the register eax

	cmp		byte [eax + tape], 0		; Check if value at cell index is 0
	je		jumpBackwards.success		; If the cell value is not 0 leave the procedure successfully

	mov		dword [ebp - 8], 1			; Set the local variable nesting level to 1

.readingLoop:
	push	SEEK_CUR
	push	-2
	push	dword [inputFileDescriptor]
	call	sysLSeek					; Move the file pointer back 2 bytes to read the file in reverse
	add		esp, 12						; Clear stack arguments

	cmp		eax, 0						; Check if the seek operation was successfully
	jl		jumpBackwards.error			; Exit the procedure unsuccessfully if it was not possible to seek to a previous character

	lea		eax, [ebp - 4]				; Store the nesting level's local variable effective address in register eax
	push	1
	push	eax
	push	dword [inputFileDescriptor]
	call	sysRead						; Read a single byte from the file
	add		esp, 12						; Clear stack arguments

	cmp		byte [ebp - 4], '['			; Check if the character read is '['
	je		jumpBackwards.leftBracket	; Decrease the nesting level if the character read is '['

	cmp		byte [ebp - 4], ']'			; Check if the character read is ']'
	je		jumpBackwards.rightBracket	; Increase the nesting level if the character read is ']', and check if it's the matching bracket

	jmp		jumpBackwards.readingLoop	; Keep reading the file

.leftBracket:
	dec		dword [ebp - 8]				; Decrement the nesting level

	cmp		dword [ebp - 8], 0			; Check if the nesting level is 0
	jne		jumpBackwards.readingLoop	; If the nesting level is not 0, the matching bracket was not found, keep reading the file

	jmp		jumpBackwards.success		; If the nesting level is 0 exit the procedure successfully

.rightBracket:
	inc		dword [ebp - 8]				; Increment the nesting level
	jmp		jumpBackwards.readingLoop	; Keep reading the file

.error:
	mov		eax, 0						; Set the failure return value
	jmp		jumpBackwards.exit			; Exit the procedure

.success:
	mov		eax, 1						; Set the successfully return value
	jmp		jumpBackwards.exit			; Exit the procedure

.exit:
	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller



printLeftBracketError:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	push	leftBracketErrorLength
	push	leftBracketError
	push	STDERR
	call	sysWrite				; Print missing left bracket error
	add		esp, 12					; Clear stack arguments

	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller



printRightBracketError:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	push	rightBracketErrorLength
	push	rightBracketError
	push	STDERR
	call	sysWrite				; Print missing left bracket error
	add		esp, 12					; Clear stack arguments

	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller



%endif