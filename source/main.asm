;	Description:
;		Implementation of the BFASM brakfuck interpreter.
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




%include "system.asm"
%include "loader.asm"
%include "interpreter.asm"




global _start




segment .rodata
	helpMessage							db	'BFASM: Brainfuck interpreter for the IA-32 architecture.', 0xA, 'Usage: bfasm <path> [tape size]', 0xA, 'Version: 2019.04.1', 0xA, 0
	helpMessageLength					equ	$ - helpMessage

	invalidArgumentCountMessage			db	'Invalid argument count.', 0xA, 'Usage: bfasm <path> [tape size]', 0xA, 0
	invalidArgumentCountMessageLength	equ	$ - invalidArgumentCountMessage

	invalidPathError					db	'Invalid path.', 0xA, 0
	invalidPathErrorLength				equ	$ - invalidPathError

	memoryError							db	'Memory error.', 0xA, 0
	memoryErrorLength					equ	$ - memoryError

	leftBracketError					db	'No matching left bracket.', 0xA, 0
	leftBracketErrorLength				equ	$ - leftBracketError

	rightBracketError					db	'No matching right bracket.', 0xA, 0
	rightBracketErrorLength				equ	$ - rightBracketError

	invalidTapeSizeError				db	'Invalid tape size.', 0xA, 0
	invalidTapeSizeErrorLength			equ	$ - invalidTapeSizeError




segment .text
;
;	Description:
;		Interpret the brainfuck instructions.
;
;	Parameters:
;		File name (optional).
;		Tape's size (optional).
;
;	Local variables:
;		Tape's size.
;		Instructions' address.
;		Instruction count.
;
;	Return:
;		None.
;
;	Notes:
;		This is the main procedure of the program.
;
_start:
	mov		ebp, esp					; Set the current procedure's base pointer.
	sub		esp, 12						; Reserve space for local variables (tape's size, instructions' address, instruction count).

	mov		dword [ebp - 4], 30000		; Set the default tape's size.

	cmp		dword [ebp], 1				; Compare the argument count with 1.
	je		_start.singleArgument		; Print the program information, if the argument count is 1.

	cmp		dword [ebp], 2				; Compare the argument count with 2.
	je		_start.doubleArguments		; Interpret the instructions, if the argument count is 2.

	cmp		dword [ebp], 3				; Compare the argument count with 3.
	je		_start.tripleArguments		; Set the tape's size, and interpret the instructions, if the argument count is 3.

	call	printArgumentCountError		; Print the invalid argument error message, if the argument count is greater than 3.

	jmp		_start.failureExit			; Exit the program with failure exit status on invalid argument count.

.singleArgument:
	call	printInformation			; Print the program information.

	jmp		_start.successExit			; Exit the program with success exit status.

.doubleArguments:
	lea		eax, [ebp - 12]				; Store the instruction count's address in eax.
	push	eax							; Push instruction count's address.
	lea		eax, [ebp - 8]				; Store the instructions' adress' address in eax.
	push	eax							; Push instructions' address' address.
	push	dword [ebp + 8]				; Push the file name.
	call	load						; Load the instructions.
	add		esp, 12						; Clear the stack arguments.

	cmp		eax, LOAD_INVALID_PATH		; Compare the return value with LOAD_INVALID_PATH.
	je		_start.invalidPath			; Print error message, and exit the program with failure exit status, on invalid file name.

	cmp		eax, ZERO_INSTRUCTIONS		; Compare the return value ZERO_INSTRUCTIONS.
	je		_start.successExit			; Exit the program with success exit status, on zero instructions.

	cmp		eax, MEMORY_ERROR			; Compare the return value with MEMORY_ERROR.
	je		_start.memoryError			; Print error message, and exit the program with failure exit status, on memory error.

	cmp		eax, MISSING_LEFT_BRACKET	; Compare the return value with MISSING_LEFT_BRACKET.
	je		_start.missingLeftBracket	; Print error message, and exit the program with failure exit status, on missing bracket.

	cmp		eax, MISSING_RIGHT_BRACKET	; Compare the return value with MISSING_RIGHT_BRACKET.
	je		_start.missingRightBracket	; Print error message, and exit the program with failure exit status, on missing bracket.

	push	dword [ebp - 4]				; Push the tape's size.
	push	dword [ebp - 12]			; Push the instruction count.
	push	dword [ebp - 8]				; Push the instructions' address.
	call	interpret					; Interpret the instructions.
	add		esp, 12						; Clear the stack arguments.

	push	dword [ebp - 12]			; Push the instruction count.
	push	dword [ebp - 8]				; Push the instructions' address.
	call	sysMUnmap					; Unmap the instructions' memory map.
	add		esp, 8						; Clear the stack arguments.

	cmp		eax, NO_ERROR				; Compare the return value with NO_ERROR.
	je		_start.successExit			; Exit the program with success exit status, on no errors.

	cmp		eax, TAPE_MEMORY_ERROR		; Compare the return value with TAPE_MEMORY_ERROR.
	je		_start.memoryError			; Print error message, and exit the program with failure exit status, on memory error.

.tripleArguments:
	push	dword [ebp + 12]			; Push the tape's size string.
	call	stoi						; Convert the tape's size string to an integer.
	add		esp, 4						; Clear the stack arguments.

	cmp		eax, -1						; Compare the return value with -1.
	je		_start.invalidTapeSize		; Print error, and exit program, if the return value is -1.

	mov		dword [ebp - 4], eax		; Set the tape's size.

	jmp		_start.doubleArguments		; Interpret the instructions.

.invalidPath:
	call	printInvalidPathError		; Print the error message.

	jmp		_start.failureExit			; Exit the program with failure exit status.

.invalidTapeSize:
	call	printInvalidTapeSizeError	; Print the error message.

	jmp		_start.failureExit			; Exit the program with failure exit status.

.memoryError:
	call	printMemoryError			; Print the error message.

	jmp		_start.failureExit			; Exit the program with failure exit status.

.missingLeftBracket:
	call	printLeftBracketError		; Print the error message.

	jmp		_start.failureExit			; Exit the program with failure exit status.

.missingRightBracket:
	call	printRightBracketError		; Print the error message.

	jmp		_start.failureExit			; Exit the program with failure exit status.

.successExit:
	push	SYS_EXIT_SUCCESS			; Set success exit status.
	call	sysExit						; Exit the program.

.failureExit:
	push	SYS_EXIT_FAILURE			; Set failure exit status.
	call	sysExit						; Exit the program.




;
;	Description:
;		Print the program information.
;
;	Return:
;		None.
;
printInformation:
	push	ebp					; Store the caller's base pointer.
	mov		ebp, esp			; Set the current procedure's base pointer.

	push	helpMessageLength	; Push the program's information's length.
	push	helpMessage			; Push the program's information.
	push	SYS_STDOUT			; Push the file descriptor.
	call	sysWrite			; Print the program information.
	add		esp, 12				; Clear the stack arguments.

	mov		esp, ebp			; Clear stack.
	pop		ebp					; Restore caller's base pointer.
	ret							; Return to caller.




;
;	Description:
;		Print the invalid argument count error message.
;
;	Return:
;		None.
;
printArgumentCountError:
	push	ebp									; Store the caller's base pointer.
	mov		ebp, esp							; Set the current procedure's base pointer.

	push	invalidArgumentCountMessageLength	; Push the error message's length.
	push	invalidArgumentCountMessage			; Push the error message.
	push	SYS_STDERR							; Push the file descriptor.
	call	sysWrite							; Print the argument count error message.
	add		esp, 12								; Clear the stack arguments.

	mov		esp, ebp							; Clear stack.
	pop		ebp									; Restore caller's base pointer.
	ret											; Return to caller.




;
;	Description:
;		Print the invalid path error message.
;
;	Return:
;		None.
;
printInvalidPathError:
	push	ebp						; Store the caller's base pointer.
	mov		ebp, esp				; Set the current procedure's base pointer.

	push	invalidPathErrorLength	; Push the error message's length.
	push	invalidPathError		; Push the error message.
	push	SYS_STDERR				; Push the file descriptor.
	call	sysWrite				; Print the invalid file name error message.
	add		esp, 12					; Clear the stack arguments.

	mov		esp, ebp				; Clear stack.
	pop		ebp						; Restore caller's base pointer.
	ret								; Return to caller.




;
;	Description:
;		Print the memory error message.
;
;	Return:
;		None.
;
printMemoryError:
	push	ebp					; Store the caller's base pointer.
	mov		ebp, esp			; Set the current procedure's base pointer.

	push	memoryErrorLength	; Push the error message's length.
	push	memoryError			; Push the error message.
	push	SYS_STDERR			; Push the file descriptor.
	call	sysWrite			; Print the memory error message.
	add		esp, 12				; Clear the stack arguments.

	mov		esp, ebp			; Clear stack.
	pop		ebp					; Restore caller's base pointer.
	ret							; Return to caller.




;
;	Description:
;		Print the missing left bracket error message.
;
;	Return:
;		None.
;
printLeftBracketError:
	push	ebp						; Store the caller's base pointer.
	mov		ebp, esp				; Set the current procedure's base pointer.

	push	leftBracketErrorLength	; Push the error message's length.
	push	leftBracketError		; Push the error message.
	push	SYS_STDERR				; Push the file descriptor.
	call	sysWrite				; Print the missing left bracket error message.
	add		esp, 12					; Clear the stack arguments.

	mov		esp, ebp				; Clear stack.
	pop		ebp						; Restore caller's base pointer.
	ret								; Return to caller.




;
;	Description:
;		Print the missing right bracket error message.
;
;	Return:
;		None.
;
printRightBracketError:
	push	ebp						; Store the caller's base pointer.
	mov		ebp, esp				; Set the current procedure's base pointer.

	push	rightBracketErrorLength	; Push the error message's length.
	push	rightBracketError		; Push the error message.
	push	SYS_STDERR				; Push the file descriptor.
	call	sysWrite				; Print the missing left bracket error message.
	add		esp, 12					; Clear the stack arguments.

	mov		esp, ebp				; Clear stack.
	pop		ebp						; Restore caller's base pointer.
	ret								; Return to caller.




;
;	Description:
;		Print the invalid tape size error message.
;
;	Return:
;		None.
;
printInvalidTapeSizeError:
	push	ebp							; Store the caller's base pointer.
	mov		ebp, esp					; Set the current procedure's base pointer.

	push	invalidTapeSizeErrorLength	; Push the error message's length.
	push	invalidTapeSizeError		; Push the error message.
	push	SYS_STDERR					; Push the file descriptor.
	call	sysWrite					; Print the missing left bracket error message.
	add		esp, 12						; Clear the stack arguments.

	mov		esp, ebp					; Clear stack.
	pop		ebp							; Restore caller's base pointer.
	ret									; Return to caller.




;
;	Description:
;		Convert string to positive integer.
;
;	Parameters:
;		Integer string.
;
;	Return:
;		On success, the integer is returned.
;		On error, -1 is returned.
;
;	Notes:
;		Only works for non-negative integers.
;
stoi:
	push	ebp						; Store the caller's base pointer.
	mov		ebp, esp				; Set the current procedure's base pointer.

	mov		ecx, dword [ebp + 8]	; Store the string in ecx.

	cmp		byte [ecx], 0			; Compare the first character with 0.
	je		stoi.error				; Exit the procedure with a failure return value, if the string is empty.

	mov		eax, 0					; Set the initial value to 0.

.convertLoop:
	mov		ecx, dword [ebp + 8]	; Store the current character's address in ecx.
	movzx	ecx, byte [ecx]			; Store the current character in ecx.

	cmp		ecx, 0					; Compare the current character with 0.
	je		stoi.exit				; Exit the procedure, if there are no more characters to be read.

	sub		ecx, '0'				; Convert the character to digit.

	cmp		ecx, 0					; Compare the digit with 0.
	jl		stoi.error				; Exit the procedure with a failure return value, if the digit is lower than 0.

	cmp		ecx, 9					; Compare the digit with 9.
	jg		stoi.error				; Exit the procedure with a failure return value, if the digit is greater than 0.

	mov		edx, 10					; Store 10 in edx.
	mul		edx						; Multiply the current value by 10.
	add		eax, ecx				; Add the digit to current value.

	inc		dword [ebp + 8]			; Increment the current character address.

	jmp		stoi.convertLoop		; Keep converting the string.

.error:
	mov		eax, -1					; Set the failure return value.

.exit:
	mov		esp, ebp				; Clear stack.
	pop		ebp						; Restore caller's base pointer.
	ret								; Return to caller.