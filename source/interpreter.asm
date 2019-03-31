;	Description:
;		Interprets brainfuck instructions, and manages the tape.




%ifndef INTERPRETER_ASM
%define INTERPRETER_ASM




%include "system.asm"




NO_ERROR			equ	0
TAPE_MEMORY_ERROR	equ -1




segment .text
interprete:
	push	ebp													; Store base pointer
	mov		ebp, esp											; Set base pointer to stack pointer
	sub		esp, 40												; Reserve 40 bytes on the stack for local variables (memory map argument structure, tape address, current instruction index, cell index, current character)

	lea		eax, [ebp - 4]										; Store the file offset's local variable effective address in register eax
	mov		dword [eax], 0										; Set file offeset to 0

	lea		eax, [ebp - 8]										; Store the file descriptor's local variable effective address in register eax
	mov		dword [eax], -1										; Set file offeset to -1

	lea		eax, [ebp - 12]										; Store the map flags' local variable effective address in register eax
	mov		dword [eax], SYS_MAP_PRIVATE | SYS_MAP_ANONYMOUS	; Set map flags to private, and anonymous

	lea		eax, [ebp - 16]										; Store the map protection's local variable effective address in register eax
	mov		dword [eax], SYS_PROT_READ | SYS_PROT_WRITE			; Set map protection to read, and write

	lea		eax, [ebp - 20]										; Store the map size's local variable effective address in register eax
	mov		ecx, dword [ebp + 20]								; Store tape size in register ecx
	mov		dword [eax], ecx

	lea		eax, [ebp - 24]										; Store the map adress's local variable effective address in register eax
	mov		dword [eax], 0										; Set map address to 0

	lea		eax, [ebp - 24]										; Store the memory map argument structure's local variable effective address in register eax

	push	eax													; Push memory map argument structure's address
	call	sysMMap												; Map memory
	add		esp, 4												; Clear stack arguments

	cmp		eax, -1												; Check if memory was mapped successfully
	je		interprete.memoryError								; Exit the procedure if the memory was not mapped successfully

	mov		dword [ebp - 28], eax
	mov		dword [ebp - 32], 0									; Set current instruction index to 0
	mov		dword [ebp - 36], 0

.readingLoop:
	mov		eax, dword [ebp - 32]								; Store current instruction index in register eax
	cmp		eax, dword [ebp + 16]								; Check if current instruction index is greater or equal to instruction size
	jge		interprete.success									; Exit procedure successfully if no more instructions

	mov		eax, [ebp + 12]										; Store instructions address in register eax
	add		eax, dword [ebp - 32]											; Add current instruction index to instructions address
	mov		al, byte [eax]										; Store character in register al
	mov		byte [ebp - 40], al									; Store al in current character

	inc		dword [ebp - 32]									; Increment current instruction index

	cmp		byte [ebp - 40], '>'								; Check if the character read is '>'
	je		interprete.greaterThan								; Process the '>' symbol

	cmp		byte [ebp - 40], '<'								; Check if the character read is '<'
	je		interprete.lessThan									; Process the '<' symbol

	cmp		byte [ebp - 40], '+'								; Check if the character read is '+'
	je		interprete.plus										; Process the '+' symbol

	cmp		byte [ebp - 40], '-'								; Check if the character read is '-'
	je		interprete.minus									; Process the '-' symbol

	cmp		byte [ebp - 40], '.'								; Check if the character read is '.'
	je		interprete.dot										; Process the '.' symbol

	cmp		byte [ebp - 40], ','								; Check if the character read is ','
	je		interprete.comma									; Process the ',' symbol

	cmp		byte [ebp - 40], '['								; Check if the character read is '['
	je		interprete.leftBracket								; Process the '[' symbol

	cmp		byte [ebp - 40], ']'								; Check if the character read is ']'
	je		interprete.rightBracket								; Process the ']' symbol

	jmp		interprete.readingLoop								; Ignore the character read if it's not a valid symbol

.greaterThan:
	push	dword [ebp + 20]
	lea		eax, [ebp - 36]
	push	eax
	call	incrementCellIndex									; Increment the cell index
	add		esp, 8
	jmp		interprete.readingLoop								; Keep reading the file

.lessThan:
	push	dword [ebp + 20]
	lea		eax, [ebp - 36]
	push	eax
	call	decrementCellIndex									; Decrement the cell index
	add		esp, 8
	jmp		interprete.readingLoop								; Keep reading the file

.plus:
	push	dword [ebp - 36]
	push	dword [ebp - 28]
	call	incrementCellValue									; Increment the cell value
	add		esp, 8
	jmp		interprete.readingLoop								; Keep reading the file

.minus:
	push	dword [ebp - 36]
	push	dword [ebp - 28]
	call	decrementCellValue									; Decrement the cell value
	add		esp, 8
	jmp		interprete.readingLoop								; Keep reading the file

.dot:
	push	dword [ebp - 36]
	push	dword [ebp - 28]
	call	printValue											; Print the cell value
	add		esp, 8
	jmp		interprete.readingLoop								; Keep reading the file

.comma:
	push	dword [ebp - 36]
	push	dword [ebp - 28]
	call	getValue											; Store a single byte of input into the cell value at index
	add		esp, 8
	jmp		interprete.readingLoop								; Keep reading the file

.leftBracket:
	push	dword [ebp - 36]
	push	dword [ebp - 28]
	lea		eax, [ebp - 32]										; Store the current instruction index's local variable effective address in register eax
	push	eax													; Push current instruction index address
	push	dword [ebp + 12]									; Push instructions' address
	call	jumpForwards										; Jump forward to the instruction after the matching ']' symbol if the current cell value is 0
	add		esp, 16												; Clear stack arguments

	jmp		interprete.readingLoop								; Keep reading the file if no error was found

.rightBracket:
	push	dword [ebp - 36]
	push	dword [ebp - 28]
	lea		eax, [ebp - 32]										; Store the current instruction index's local variable effective address in register eax
	push	eax													; Push current instruction index address
	push	dword [ebp + 12]									; Push instructions' address
	call	jumpBackwards										; Jump backwards to the instruction after the matching '[' symbol if the current cell value is not 0
	add		esp, 16												; Clear stack arguments

	jmp		interprete.readingLoop								; Keep reading the file if no error was found

.memoryError:
	mov		eax, TAPE_MEMORY_ERROR								; Set the failure return value
	jmp		interprete.exit										; Exit the procedure

.success:
	mov		eax, NO_ERROR										; Set the success return value
	jmp		interprete.exit										; Exit the procedure

.exit:
	mov		esp, ebp											; Clear stack
	pop		ebp													; Restore base pointer
	ret															; Return to caller




incrementCellIndex:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	mov		eax, dword [ebp + 8]
	inc		dword [eax]				; Increment cell index

	mov		ecx, dword [ebp + 12]	; Load tape size in register eax

	cmp		dword [eax], ecx		; Check if the index is out of the tape bounds
	jl		incrementCellIndex.exit	; Exit procedure if the index is not out of bounds

	mov		dword [eax], 0			; Wrap index back to the first cell

.exit:
	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller




decrementCellIndex:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	mov		eax, dword [ebp + 8]
	dec		dword [eax]				; Decrement cell index

	cmp		dword [eax], 0			; Check if the index is out of the tape bounds
	jge		incrementCellIndex.exit	; Exit procedure if the index is not out of bounds

	mov		ecx, dword [ebp + 12]	; Load tape size in register eax
	dec		ecx						; Decrement tape size to get last index

	mov		dword [eax], ecx		; Wrap around to the last cell

.exit:
	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller




incrementCellValue:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer

	mov		ecx, dword [ebp + 8]		; Load tape address in register ecx

	mov		eax, dword [ebp + 12]		; Load cell index into the register eax
	inc		byte [eax + ecx]			; Increment cell value at the index

	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller




decrementCellValue:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer

	mov		ecx, dword [ebp + 8]		; Load tape address in register ecx

	mov		eax, dword [ebp + 12]		; Load cell index into the register eax
	dec		byte [eax + ecx]			; Increment cell value at the index

	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller




printValue:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer

	mov		eax, dword [ebp + 8]		; Load tape address into register eax
	add		eax, dword [ebp + 12]		; Add cell index offset to the tape address

	push	1
	push	eax
	push	SYS_STDOUT
	call	sysWrite					; Print cell value at index
	add		esp, 12						; Clear stack arguments

	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller




getValue:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer

	mov		eax, dword [ebp + 8]		; Load tape address into register eax
	add		eax, dword [ebp + 12]		; Add cell index offset to the tape address

	push	1
	push	eax
	push	SYS_STDIN
	call	sysRead						; Store input into the cell at index
	add		esp, 12						; Clear stack arguments

	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller




jumpForwards:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer
	sub		esp, 8						; Reserve 8 bytes on the stack for local variables (current character, and nesting level)

	mov		eax, dword [ebp + 20]		; Load cell index into the register eax

	mov		ecx, dword [ebp + 16]		; Load tape address into the register ecx

	cmp		byte [eax + ecx], 0			; Check if value at cell index is 0
	jne		jumpForwards.exit			; If the cell value is not 0 leave procedure successfully

	mov		dword [ebp - 4], 1			; Set the local variable nesting level to 1

.readingLoop:
	mov		eax, [ebp + 8]				; Store instructions address in register eax

	mov		ecx, dword [ebp + 12]		; Store instructions address's address in register eax

	add		eax, dword [ecx]			; Add current instruction index to instructions address

	mov		al, byte [eax]				; Store character in register al
	mov		byte [ebp - 8], al			; Store al in current character

	mov		eax, dword [ebp + 12]		; Store current index address in register eax
	inc		dword [eax]					; Increment current instruction index

	cmp		byte [ebp - 8], '['			; Check if the character read is '['
	je		jumpForwards.leftBracket	; Increase the nesting level if the character read is '['

	cmp		byte [ebp - 8], ']'			; Check if the character read is ']'
	je		jumpForwards.rightBracket	; Decrease the nesting level if the character read is ']', and check if it's the matching bracket

	jmp		jumpForwards.readingLoop	; Keep reading the file

.leftBracket:
	inc		dword [ebp - 4]				; Increment the nesting level
	jmp		jumpForwards.readingLoop	; Keep reading the file

.rightBracket:
	dec		dword [ebp - 4]				; Decrement the nesting level

	cmp		dword [ebp - 4], 0			; Check if the nesting level is 0
	jne		jumpForwards.readingLoop	; If the nesting level is not 0, the matching bracket was not found, keep reading the file

.exit:
	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller




jumpBackwards:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer
	sub		esp, 8						; Reserve 8 bytes on the stack for local variables (current character, and nesting level)

	mov		eax, dword [ebp + 20]		; Load cell index into the register eax

	mov		ecx, dword [ebp + 16]		; Load tape address into the register ecx

	cmp		byte [eax + ecx], 0			; Check if value at cell index is 0
	je		jumpBackwards.exit			; If the cell value is not 0 leave the procedure successfully

	mov		dword [ebp - 4], 1			; Set the local variable nesting level to 1

.readingLoop:
	mov		eax, dword [ebp + 12]		; Store current index address in register eax
	sub		dword [eax], 2				; Subtract 2 from current index

	mov		eax, [ebp + 8]				; Store instructions address in register eax

	mov		ecx, dword [ebp + 12]		; Store instructions address's address in register eax

	add		eax, dword [ecx]			; Add current instruction index to instructions address

	mov		al, byte [eax]				; Store character in register al
	mov		byte [ebp - 8], al			; Store al in current character

	mov		eax, dword [ebp + 12]		; Store current index address in register eax
	inc		dword [eax]					; Increment current instruction index

	cmp		byte [ebp - 8], '['			; Check if the character read is '['
	je		jumpBackwards.leftBracket	; Decrease the nesting level if the character read is '['

	cmp		byte [ebp - 8], ']'			; Check if the character read is ']'
	je		jumpBackwards.rightBracket	; Increase the nesting level if the character read is ']', and check if it's the matching bracket

	jmp		jumpBackwards.readingLoop	; Keep reading the file

.rightBracket:
	inc		dword [ebp - 4]				; Increment the nesting level
	jmp		jumpBackwards.readingLoop	; Keep reading the file

.leftBracket:
	dec		dword [ebp - 4]				; Decrement the nesting level

	cmp		dword [ebp - 4], 0			; Check if the nesting level is 0
	jne		jumpBackwards.readingLoop	; If the nesting level is not 0, the matching bracket was not found, keep reading the file

.exit:
	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller




%endif