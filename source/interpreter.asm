%ifndef INTERPRETER_ASM
%define INTERPRETER_ASM



%include "system.asm"



NO_ERROR				equ	0
INVALID_PATH			equ	-1
TAPE_MEMORY_ERROR		equ -2



segment .data
	cellIndex		dd	0



segment .bss
	tapeAddress	resd	1
	size		resd	1



segment .text
interprete:
	push	ebp											; Store base pointer
	mov		ebp, esp									; Set base pointer to stack pointer
	sub		esp, 32										; Reserve 32 bytes on the stack for local variables (current character, current instruction index, memory map argument structure)

	mov		dword [ebp - 8], 0							; Set current instruction index to 0

	mov		eax, dword [ebp + 20]						; Load tape size argument in register eax
	mov		dword [size], eax							; Store tape size in size global variable

	lea		eax, [ebp - 12]								; Store the file offset's local variable effective address in register eax
	mov		dword [eax], 0								; Set file offeset to 0

	lea		eax, [ebp - 16]								; Store the file descriptor's local variable effective address in register eax
	mov		dword [eax], -1								; Set file offeset to -1

	lea		eax, [ebp - 20]								; Store the map flags' local variable effective address in register eax
	mov		dword [eax], MAP_PRIVATE | MAP_ANONYMOUS	; Set map flags to private, and anonymous

	lea		eax, [ebp - 24]								; Store the map protection's local variable effective address in register eax
	mov		dword [eax], PROT_READ | PROT_WRITE			; Set map protection to read, and write

	lea		eax, [ebp - 28]								; Store the map size's local variable effective address in register eax
	mov		ecx, dword [size]							; Store tape size in register ecx
	mov		dword [eax], ecx

	lea		eax, [ebp - 32]								; Store the map adress's local variable effective address in register eax
	mov		dword [eax], 0								; Set map address to 0

	lea		eax, [ebp - 32]								; Store the memory map argument structure's local variable effective address in register eax

	push	eax											; Push memory map argument structure's address
	call	sysMMap										; Map memory
	add		esp, 4										; Clear stack arguments

	cmp		eax, -1										; Check if memory was mapped successfully
	je		interprete.memoryError						; Exit the procedure if the memory was not mapped successfully

	mov		dword [tapeAddress], eax					; Store the memory map address in local variable

.readingLoop:
	mov		eax, dword [ebp - 8]						; Store current instruction index in register eax
	cmp		eax, dword [ebp + 16]						; Check if current instruction index is greater or equal to instruction size
	jge		interprete.success							; Exit procedure successfully if no more instructions

	mov		eax, [ebp + 12]								; Store instructions address in register eax
	mov		ecx, dword [ebp - 8]						; Store current instruction index in register ecx
	add		eax, ecx									; Add current instruction index to instructions address
	mov		al, byte [eax]								; Store character in register al
	mov		byte [ebp - 4], al							; Store al in current character

	inc		dword [ebp - 8]								; Increment current instruction index

	cmp		byte [ebp - 4], '>'							; Check if the character read is '>'
	je		interprete.greaterThan						; Process the '>' symbol

	cmp		byte [ebp - 4], '<'							; Check if the character read is '<'
	je		interprete.lessThan							; Process the '<' symbol

	cmp		byte [ebp - 4], '+'							; Check if the character read is '+'
	je		interprete.plus								; Process the '+' symbol

	cmp		byte [ebp - 4], '-'							; Check if the character read is '-'
	je		interprete.minus							; Process the '-' symbol

	cmp		byte [ebp - 4], '.'							; Check if the character read is '.'
	je		interprete.dot								; Process the '.' symbol

	cmp		byte [ebp - 4], ','							; Check if the character read is ','
	je		interprete.comma							; Process the ',' symbol

	cmp		byte [ebp - 4], '['							; Check if the character read is '['
	je		interprete.leftBracket						; Process the '[' symbol

	cmp		byte [ebp - 4], ']'							; Check if the character read is ']'
	je		interprete.rightBracket						; Process the ']' symbol

	jmp interprete.readingLoop							; Ignore the character read if it's not a valid symbol

.greaterThan:
	call	incrementCellIndex							; Increment the cell index
	jmp		interprete.readingLoop						; Keep reading the file

.lessThan:
	call	decrementCellIndex							; Decrement the cell index
	jmp		interprete.readingLoop						; Keep reading the file

.plus:
	call	incrementCellValue							; Increment the cell value
	jmp		interprete.readingLoop						; Keep reading the file

.minus:
	call	decrementCellValue							; Decrement the cell value
	jmp		interprete.readingLoop						; Keep reading the file

.dot:
	call	printValue									; Print the cell value
	jmp		interprete.readingLoop						; Keep reading the file

.comma:
	call	getValue									; Store a single byte of input into the cell value at index
	jmp		interprete.readingLoop						; Keep reading the file

.leftBracket:
	lea		eax, [ebp - 8]								; Store the current instruction index's local variable effective address in register eax
	push	eax											; Push current instruction index address
	push	dword [ebp + 16]							; Push instruction size
	push	dword [ebp + 12]							; Push instructions' address
	call	jumpForwards								; Jump forward to the instruction after the matching ']' symbol if the current cell value is 0
	add		esp, 12										; Clear stack arguments

	cmp		eax, NO_ERROR								; Check if any error occurred when jumping forward (missing matching bracket)
	je		interprete.readingLoop						; Keep reading the file if no error was found

	jmp		interprete.exit								; Exit the procedure with a failure return value

.rightBracket:
	lea		eax, [ebp - 8]								; Store the current instruction index's local variable effective address in register eax
	push	eax											; Push current instruction index address
	push	dword [ebp + 16]							; Push instruction size
	push	dword [ebp + 12]							; Push instructions' address
	call	jumpBackwards								; Jump backwards to the instruction after the matching '[' symbol if the current cell value is not 0
	add		esp, 12										; Clear stack arguments

	cmp		eax, NO_ERROR								; Check if any error occurred when jumping backwards (missing matching bracket)
	je		interprete.readingLoop						; Keep reading the file if no error was found

	jmp		interprete.exit								; Exit the procedure with a failure return value

.invalidPath:
	mov		eax, INVALID_PATH							; Set the failure return value
	jmp		interprete.exit								; Exit the procedure

.memoryError:
	mov		eax, TAPE_MEMORY_ERROR						; Set the failure return value
	jmp		interprete.exit								; Exit the procedure

.success:
	mov		eax, NO_ERROR								; Set the success return value
	jmp		interprete.exit								; Exit the procedure

.exit:
	mov		esp, ebp									; Clear stack
	pop		ebp											; Restore base pointer
	ret													; Return to caller



incrementCellIndex:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	inc		dword [cellIndex]		; Increment cell index

	mov		eax, dword [size]		; Load tape size in register eax

	cmp		dword [cellIndex], eax	; Check if the index is out of the tape bounds
	jl		incrementCellIndex.exit	; Exit procedure if the index is not out of bounds

	mov		dword [cellIndex], 0	; Wrap index back to the first cell

.exit:
	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller



decrementCellIndex:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	dec		dword [cellIndex]		; Decrement cell index

	cmp		dword [cellIndex], 0	; Check if the index is out of the tape bounds
	jge		incrementCellIndex.exit	; Exit procedure if the index is not out of bounds

	mov		eax, dword [size]		; Load tape size in register eax
	dec		eax						; Decrement tape size to get last index

	mov		dword [cellIndex], eax	; Wrap around to the last cell

.exit:
	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller



incrementCellValue:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer

	mov		ecx, dword [tapeAddress]	; Load tape address in register ecx

	mov		eax, dword [cellIndex]		; Load cell index into the register eax
	inc		byte [eax + ecx]			; Increment cell value at the index

	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller



decrementCellValue:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer

	mov		ecx, dword [tapeAddress]	; Load tape address in register ecx

	mov		eax, dword [cellIndex]		; Load cell index into the register eax
	dec		byte [eax + ecx]			; Increment cell value at the index

	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller



printValue:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer

	mov		eax, dword [tapeAddress]	; Load tape address into register eax
	add		eax, dword [cellIndex]		; Add cell index offset to the tape address

	push	1
	push	eax
	push	STDOUT
	call	sysWrite					; Print cell value at index
	add		esp, 12						; Clear stack arguments

	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller



getValue:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer

	mov		eax, dword [tapeAddress]	; Load tape address into register eax
	add		eax, dword [cellIndex]		; Add cell index offset to the tape address

	push	1
	push	eax
	push	STDIN
	call	sysRead						; Store input into the cell at index
	add		esp, 12						; Clear stack arguments

	mov		eax, dword [tapeAddress]	; Load tape address into register eax
	add		eax, dword [cellIndex]		; Add cell index offset to the tape address

	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller



jumpForwards:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer
	sub		esp, 8						; Reserve 8 bytes on the stack for local variables (current character, and nesting level)

	mov		eax, dword [cellIndex]		; Load cell index into the register eax

	mov		ecx, dword [tapeAddress]	; Load tape address into the register ecx

	cmp		byte [eax + ecx], 0			; Check if value at cell index is 0
	jne		jumpForwards.success		; If the cell value is not 0 leave procedure successfully

	mov		dword [ebp - 8], 1			; Set the local variable nesting level to 1

.readingLoop:
	mov		eax, [ebp + 8]				; Store instructions address in register eax

	mov		ecx, dword [ebp + 16]		; Store instructions address's address in register eax
	mov		ecx, dword [ecx]			; Store current instruction index in register ecx

	add		eax, ecx					; Add current instruction index to instructions address

	mov		al, byte [eax]				; Store character in register al
	mov		byte [ebp - 4], al			; Store al in current character

	mov		eax, dword [ebp + 16]		; Store current index address in register eax
	inc		dword [eax]					; Increment current instruction index

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

.success:
	mov		eax, NO_ERROR				; Set the successfully return value
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

	mov		ecx, dword [tapeAddress]	; Load tape address into the register ecx

	cmp		byte [eax + ecx], 0			; Check if value at cell index is 0
	je		jumpBackwards.success		; If the cell value is not 0 leave the procedure successfully

	mov		dword [ebp - 8], 1			; Set the local variable nesting level to 1

.readingLoop:
	mov		eax, dword [ebp + 16]		; Store current index address in register eax
	sub		dword [eax], 2				; Subtract 2 from current index

	mov		eax, [ebp + 8]				; Store instructions address in register eax

	mov		ecx, dword [ebp + 16]		; Store instructions address's address in register eax
	mov		ecx, dword [ecx]			; Store current instruction index in register ecx

	add		eax, ecx					; Add current instruction index to instructions address

	mov		al, byte [eax]				; Store character in register al
	mov		byte [ebp - 4], al			; Store al in current character

	mov		eax, dword [ebp + 16]		; Store current index address in register eax
	inc		dword [eax]					; Increment current instruction index


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

.success:
	mov		eax, NO_ERROR				; Set the successfully return value
	jmp		jumpBackwards.exit			; Exit the procedure

.exit:
	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller



%endif