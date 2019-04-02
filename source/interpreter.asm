;	Description:
;		Interprets brainfuck instructions, and manages the tape.
;
;	License:
;		MIT License
;
;		Copyright (c) 2019 Miguel Sousa
;
;		Permission is hereby granted, free of charge, to any person obtaining a copy
;		of this software and associated documentation files (the "Software"), to deal
;		in the Software without restriction, including without limitation the rights
;		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;		copies of the Software, and to permit persons to whom the Software is
;		furnished to do so, subject to the following conditions:
;
;		The above copyright notice and this permission notice shall be included in all
;		copies or substantial portions of the Software.
;
;		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;		SOFTWARE.
;




%ifndef INTERPRETER_ASM
%define INTERPRETER_ASM




%include "system.asm"




NO_ERROR			equ	0	; Instructions interpreted successfully.
TAPE_MEMORY_ERROR	equ -1	; Error when mapping memory.




segment .text
;
;	Description:
;		Interpret instructions, and manage the tape.
;
;	Parameters:
;		Instructions' address.
;		Instruction count.
;		Tape size.
;
;	Local variables:
;		File offset (part of the memory map argument structure).
;		File descriptor (part of the memory map argument structure).
;		Map flags (part of the memory map argument structure).
;		Map protection (part of the memory map argument structure).
;		Map size (part of the memory map argument structure).
;		Map address (part of the memory map argument structure).
;		Tape's address.
;		Instruction index.
;		Cell index.
;		Last instruction read.
;
;	Return:
;		On success, NO_ERROR is returned.
;		On error, TAPE_MEMORY_ERROR is returned (the only error return value).
;
;	Notes:
;		Assumes that the instructions, and the instruction count, are valid.
;
interpret:
	push	ebp									; Store the caller's base pointer.
	mov		ebp, esp							; Set the current procedure's base pointer.
	sub		esp, 40								; Reserve space for local variables (memory map argument structure, tape address, current instruction index, cell index, current character).

	mov		dword [ebp - 4], 0					; Set the file offeset to 0 (ignored without a file).

	mov		dword [ebp - 8], -1					; Set the file descriptor to -1 (map not backed by any file).

	mov		dword [ebp - 12], SYS_MAP_PRIVANON	; Set the map flags.

	mov		dword [ebp - 16], SYS_PROT_RDWR		; Set the map protection.

	mov		ecx, dword [ebp + 16]				; Store the tape size in ecx.
	mov		dword [ebp - 20], ecx				; Set the map size to the tape size.

	mov		dword [ebp - 24], 0					; Set the map address to 0 (let the kernel choose the address).

	lea		eax, [ebp - 24]						; Store the memory map argument structure's address in eax.

	push	eax									; Push the memory map argument structure's address.
	call	sysMMap								; Map memory.
	add		esp, 4								; Clear the stack arguments.

	cmp		eax, -1								; Compare the system call return value with -1.
	je		interpret.memoryError				; Exit the procedure if the memory was not mapped successfully.

	mov		dword [ebp - 28], eax				; Set the memory map address.
	mov		dword [ebp - 32], 0					; Set the instruction index to 0.
	mov		dword [ebp - 36], 0					; Set the cell index to 0.

.readingLoop:
	mov		eax, dword [ebp - 32]				; Store the instruction index in eax.

	cmp		eax, dword [ebp + 12]				; Compare the instruction index with the instruction count.
	jge		interpret.success					; Exit the procedure successfully if the instruction index is equal, or greater, than the instruction count.

	mov		eax, [ebp + 8]						; Store the instructions' address in eax.
	add		eax, dword [ebp - 32]				; Add the instruction index to the instructions' address.
	mov		al, byte [eax]						; Store the instruction in al.
	mov		byte [ebp - 40], al					; Store the instruction in the current instruction.

	inc		dword [ebp - 32]					; Increment the instruction index.

	cmp		byte [ebp - 40], '>'				; Compare the instruction read with '>'.
	je		interpret.greaterThan				; Increase the cell index, if the instruction read is '>'.

	cmp		byte [ebp - 40], '<'				; Compare the instruction read with '<'.
	je		interpret.lessThan					; Decrease the cell index, if the instruction read is '<'.

	cmp		byte [ebp - 40], '+'				; Compare the instruction read with '+'.
	je		interpret.plus						; Increase the cell value, if the instruction read is '+'.

	cmp		byte [ebp - 40], '-'				; Compare the instruction read with '-'.
	je		interpret.minus						; Decrease the cell value, if the instruction read is '-'.

	cmp		byte [ebp - 40], '.'				; Compare the instruction read with '.'.
	je		interpret.dot						; Print the cell value, if the instruction read is '.'.

	cmp		byte [ebp - 40], ','				; Compare the instruction read with ','.
	je		interpret.comma						; Read input into the cell value, if the instruction read is ','.

	cmp		byte [ebp - 40], '['				; Compare the instruction read with '['.
	je		interpret.leftBracket				; Jump forwards, if the instruction read is '['.

	cmp		byte [ebp - 40], ']'				; Compare the instruction read with ']'.
	je		interpret.rightBracket				; Jump backwards, if the instruction read is ']'.

.greaterThan:
	push	dword [ebp + 16]					; Push the tape size.
	lea		eax, [ebp - 36]						; Store the cell index's address in eax.
	push	eax									; Push the cell index's address.
	call	incrementCellIndex					; Increment the cell index.
	add		esp, 8								; Clear the stack arguments.

	jmp		interpret.readingLoop				; Keep reading the instructions.

.lessThan:
	push	dword [ebp + 16]					; Push the tape size.
	lea		eax, [ebp - 36]						; Store the cell index's address in eax.
	push	eax									; Push the cell index's address.
	call	decrementCellIndex					; Decrement the cell index.
	add		esp, 8								; Clear the stack arguments.

	jmp		interpret.readingLoop				; Keep reading the instructions.

.plus:
	push	dword [ebp - 36]					; Push the cell index.
	push	dword [ebp - 28]					; Push the tape's address.
	call	incrementCellValue					; Increment the cell value
	add		esp, 8								; Clear the stack arguments.

	jmp		interpret.readingLoop				; Keep reading the instructions.

.minus:
	push	dword [ebp - 36]					; Push the cell index.
	push	dword [ebp - 28]					; Push the tape's address.
	call	decrementCellValue					; Decrement the cell value.
	add		esp, 8								; Clear the stack arguments.

	jmp		interpret.readingLoop				; Keep reading the instructions.

.dot:
	push	dword [ebp - 36]					; Push the cell index.
	push	dword [ebp - 28]					; Push the tape's address.
	call	printValue							; Print the cell value.
	add		esp, 8								; Clear the stack arguments.

	jmp		interpret.readingLoop				; Keep reading the instructions.

.comma:
	push	dword [ebp - 36]					; Push the cell index.
	push	dword [ebp - 28]					; Push the tape's address.
	call	getValue							; Read input into the cell value.
	add		esp, 8								; Clear the stack arguments.

	jmp		interpret.readingLoop				; Keep reading the instructions.

.leftBracket:
	push	dword [ebp - 36]					; Push the cell index.
	push	dword [ebp - 28]					; Push the tape's address.
	lea		eax, [ebp - 32]						; Store the instruction index's address in eax.
	push	eax									; Push the instruction index's address.
	push	dword [ebp + 8]						; Push instructions' address.
	call	jumpForwards						; Jump forward.
	add		esp, 16								; Clear the stack arguments.

	jmp		interpret.readingLoop				; Keep reading the file.

.rightBracket:
	push	dword [ebp - 36]					; Push the cell index.
	push	dword [ebp - 28]					; Push the tape's address.
	lea		eax, [ebp - 32]						; Store the instruction index's address in eax.
	push	eax									; Push the instruction index's address.
	push	dword [ebp + 8]						; Push instructions' address.
	call	jumpBackwards						; Jump backwards.
	add		esp, 16								; Clear the stack arguments.

	jmp		interpret.readingLoop				; Keep reading the file.

.memoryError:
	mov		eax, TAPE_MEMORY_ERROR				; Set the failure return value.
	jmp		interpret.exit						; Exit the procedure.

.success:
	push	dword [ebp + 16]					; Push the tape size.
	push	dword [ebp - 28]					; Push the tape's address.
	call	sysMUnmap							; Unmap the memory map.
	add		esp, 8								; Clear the stack arguments.

	mov		eax, NO_ERROR						; Set the success return value.
	jmp		interpret.exit						; Exit the procedure.

.exit:
	mov		esp, ebp							; Clear stack.
	pop		ebp									; Restore caller's base pointer.
	ret											; Return to caller.




;
;	Description:
;		Increment the cell index.
;
;	Parameters:
;		Cell index's address.
;		Tape size.
;
;	Return:
;		None.
;
incrementCellIndex:
	push	ebp						; Store the caller's base pointer.
	mov		ebp, esp				; Set the current procedure's base pointer.

	mov		eax, dword [ebp + 8]	; Store the cell index's address in eax.
	inc		dword [eax]				; Increment the cell index.

	mov		ecx, dword [ebp + 12]	; Store the tape size in ecx.

	cmp		dword [eax], ecx		; Compare the cell index with the tape size.
	jl		incrementCellIndex.exit	; Exit procedure if the index is not out of bounds.

	mov		dword [eax], 0			; Wrap the index back to the first cell.

.exit:
	mov		esp, ebp				; Clear stack.
	pop		ebp						; Restore caller's base pointer.
	ret								; Return to caller.




;
;	Description:
;		Decrement the cell index.
;
;	Parameters:
;		Cell index's address.
;		Tape size.
;
;	Return:
;		None.
;
decrementCellIndex:
	push	ebp						; Store the caller's base pointer.
	mov		ebp, esp				; Set the current procedure's base pointer.

	mov		eax, dword [ebp + 8]	; Store the cell index's address in eax.
	dec		dword [eax]				; Decrement the cell index.

	cmp		dword [eax], 0			; Compare the cell index with the tape size.
	jge		incrementCellIndex.exit	; Exit procedure if the index is not out of bounds.

	mov		ecx, dword [ebp + 12]	; Store the tape size in ecx.
	dec		ecx						; Decrement the tape size to get last index.

	mov		dword [eax], ecx		; Wrap the index to the last cell.

.exit:
	mov		esp, ebp				; Clear stack.
	pop		ebp						; Restore caller's base pointer.
	ret								; Return to caller.




;
;	Description:
;		Increment the value of the current cell.
;
;	Parameters:
;		Tape's addres.
;		Cell index.
;
;	Return:
;		None.
;
incrementCellValue:
	push	ebp						; Store the caller's base pointer.
	mov		ebp, esp				; Set the current procedure's base pointer.

	mov		eax, dword [ebp + 8]	; Store the tape's address in eax.
	add		eax, dword [ebp + 12]	; Add the cell index to the tape's address.

	inc		byte [eax]				; Increment the cell value at the index.

	mov		esp, ebp				; Clear stack.
	pop		ebp						; Restore caller's base pointer.
	ret								; Return to caller.




;
;	Description:
;		Decrement the value of the current cell.
;
;	Parameters:
;		Tape's addres.
;		Cell index.
;
;	Return:
;		None.
;
decrementCellValue:
	push	ebp						; Store the caller's base pointer.
	mov		ebp, esp				; Set the current procedure's base pointer.

	mov		eax, dword [ebp + 8]	; Store the tape's address in eax.
	add		eax, dword [ebp + 12]	; Add the cell index to the tape's address.

	dec		byte [eax]				; Decrement the cell value at the index.

	mov		esp, ebp				; Clear stack.
	pop		ebp						; Restore caller's base pointer.
	ret								; Return to caller.




;
;	Description:
;		Print the value of the current cell.
;
;	Parameters:
;		Tape's address.
;		Cell index.
;
;	Return:
;		None.
;
printValue:
	push	ebp						; Store the caller's base pointer.
	mov		ebp, esp				; Set the current procedure's base pointer.

	mov		eax, dword [ebp + 8]	; Store the tape's address in eax.
	add		eax, dword [ebp + 12]	; Add the cell index offset to the tape address.

	push	1						; Push the amount of bytes to be written.
	push	eax						; Push the cell's address.
	push	SYS_STDOUT				; Push the standard output file descriptor.
	call	sysWrite				; Print the cell value at index.
	add		esp, 12					; Clear the stack arguments.

	mov		esp, ebp				; Clear stack.
	pop		ebp						; Restore caller's base pointer.
	ret								; Return to caller.




;
;	Description:
;		Read a byte of input and save the it in the current cell.
;
;	Parameters:
;		Tape's address.
;		Cell index.
;
;	Return:
;		None.
;
getValue:
	push	ebp						; Store the caller's base pointer.
	mov		ebp, esp				; Set the current procedure's base pointer.

	mov		eax, dword [ebp + 8]	; Store the tape's address in eax.
	add		eax, dword [ebp + 12]	; Add the cell index offset to the tape address.

	push	1						; Push the amount of bytes to be read.
	push	eax						; Push the cell's address.
	push	SYS_STDIN				; Push the standard input file descriptor.
	call	sysRead					; Read input into the cell value.
	add		esp, 12					; Clear the stack arguments.

	mov		esp, ebp				; Clear stack.
	pop		ebp						; Restore caller's base pointer.
	ret								; Return to caller.




;
;	Description:
;		Advance the instruction index to the matching right bracket, if the current cell's value is 0.
;
;	Parameters:
;		Instructions' address.
;		Instruction index's address.
;		Tape's address.
;		Cell index.
;
;	Local variables:
;		Bracket nesting level.
;		Last instruction read.
;
;	Return:
;		None.
;
;	Notes:
;		Assumes that the bracket instructions have matching pairs.
;
jumpForwards:
	push	ebp							; Store the caller's base pointer.
	mov		ebp, esp					; Set the current procedure's base pointer.
	sub		esp, 8						; Reserve space for local variables (last instructions, bracket nesting level).

	mov		eax, dword [ebp + 16]		; Store the tape's address in eax.
	add		eax, dword [ebp + 20]		; Add the cell index to the tape's address.

	cmp		byte [eax], 0				; Compare the cell value with 0.
	jne		jumpForwards.exit			; If the cell value is not 0, exit the procedure.

	mov		dword [ebp - 4], 1			; Set the nesting level to 1.

.readingLoop:
	mov		eax, [ebp + 8]				; Store the instructions' address in eax.

	mov		ecx, dword [ebp + 12]		; Store the instructions index's address in ecx.

	add		eax, dword [ecx]			; Add the instructions index to the instructions' address.

	mov		al, byte [eax]				; Store the instruction read in al.
	mov		byte [ebp - 8], al			; Store the instruction read in the last instruction.

	mov		eax, dword [ebp + 12]		; Store the instructions index's address in eax.
	inc		dword [eax]					; Increment the instructions index.

	cmp		byte [ebp - 8], '['			; Compare the instruction read with '['.
	je		jumpForwards.leftBracket	; Increase the nesting level, if the character read is '['.

	cmp		byte [ebp - 8], ']'			; Compare the instruction read with ']'.
	je		jumpForwards.rightBracket	; Decrease the nesting level, if the character read is ']', and check if it's the matching bracket.

	jmp		jumpForwards.readingLoop	; Keep reading the instructions.

.leftBracket:
	inc		dword [ebp - 4]				; Increment the nesting level.
	jmp		jumpForwards.readingLoop	; Keep reading the instructions.

.rightBracket:
	dec		dword [ebp - 4]				; Decrement the nesting level.

	cmp		dword [ebp - 4], 0			; Compare the nesting level with 0.
	jne		jumpForwards.readingLoop	; If the nesting level is not 0, the matching bracket was not found, keep reading the instructions.

.exit:
	mov		esp, ebp					; Clear stack.
	pop		ebp							; Restore caller's base pointer.
	ret									; Return to caller.




;
;	Description:
;		Advance the instruction index to the matching left bracket, if the current cell's value is not 0.
;
;	Parameters:
;		Instructions' address.
;		Instruction index's address.
;		Tape's address.
;		Cell index.
;
;	Local variables:
;		Bracket nesting level.
;		Last instruction read.
;
;	Return:
;		None.
;
;	Notes:
;		Assumes that the bracket instructions have matching pairs.
;
jumpBackwards:
	push	ebp							; Store the caller's base pointer.
	mov		ebp, esp					; Set the current procedure's base pointer.
	sub		esp, 8						; Reserve space for local variables (last instructions, bracket nesting level).

	mov		eax, dword [ebp + 16]		; Store the tape's address in eax.
	add		eax, dword [ebp + 20]		; Add the cell index to the tape's address.

	cmp		byte [eax], 0				; Compare the cell value with 0.
	je		jumpBackwards.exit			; If the cell value is 0, exit the procedure.

	mov		dword [ebp - 4], 1			; Set the nesting level to 1.

.readingLoop:
	mov		eax, dword [ebp + 12]		; Store the instructions index's address in eax.
	sub		dword [eax], 2				; Subtract 2 from the instruction index.

	mov		eax, [ebp + 8]				; Store the instructions' address in eax.

	mov		ecx, dword [ebp + 12]		; Store the instructions index's address in ecx.

	add		eax, dword [ecx]			; Add the instructions index to the instructions' address.

	mov		al, byte [eax]				; Store the instruction read in al.
	mov		byte [ebp - 8], al			; Store the instruction read in the last instruction.

	mov		eax, dword [ebp + 12]		; Store the instructions index's address in eax.
	inc		dword [eax]					; Increment the instructions index.

	cmp		byte [ebp - 8], '['			; Compare the instruction read with '['.
	je		jumpBackwards.leftBracket	; Decrease the nesting level, if the character read is '[', and check if it's the matching bracket.

	cmp		byte [ebp - 8], ']'			; Compare the instruction read with ']'.
	je		jumpBackwards.rightBracket	; Increase the nesting level, if the character read is ']'.

	jmp		jumpBackwards.readingLoop	; Keep reading the instructions.

.rightBracket:
	inc		dword [ebp - 4]				; Increment the nesting level.
	jmp		jumpBackwards.readingLoop	; Keep reading the instructions.

.leftBracket:
	dec		dword [ebp - 4]				; Decrement the nesting level.

	cmp		dword [ebp - 4], 0			; Compare the nesting level with 0.
	jne		jumpBackwards.readingLoop	; If the nesting level is not 0, the matching bracket was not found, keep reading the instructions.

.exit:
	mov		esp, ebp					; Clear stack.
	pop		ebp							; Restore caller's base pointer.
	ret									; Return to caller.




%endif