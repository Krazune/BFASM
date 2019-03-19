%ifndef LOADER_ASM
%define LOADER_ASM



%include "system.asm"



LOAD_SUCCESS		equ	0
INVALID_PATH		equ	-1
ZERO_INSTRUCTIONS	equ	-2



segment .text
load:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer
	sub		esp, 8					; Reserve 4 bytes on the stack for local variables (file descriptor, instruction count)

	push	0						; Mode is ignored on read only
	push	RDONLY
	push	dword [ebp + 8]			; File path received as argument
	call	sysOpen					; Open file
	add		esp, 12					; Clear stack arguments

	cmp		eax, 0					; Check if the file was open successfully
	jl		load.invalidPath		; Exit the procedure if the file was not open successfully

	mov		dword [ebp - 4], eax	; Store file descriptor

	push	dword [ebp - 4]			; Push file descriptor number
	call	instructionCount		; Count instructions
	add		esp, 4					; Clear stack arguments

	cmp		eax, 0					; Check if zero count
	je		load.zeroInstructions	; Exit procedure with zero instruction return value

	mov		dword [ebp - 8], eax	; Store instruction count

	push	dword [ebp - 4]			; Push file descriptor number
	call	sysClose				; Close the open file descriptor
	add		esp, 4					; Clear stack arguments

	jmp		load.success			; Exit the procedure successfully

.invalidPath:
	mov		eax, INVALID_PATH		; Set the failure return value
	jmp		load.exit				; Exit the procedure

.zeroInstructions:
	mov		eax, ZERO_INSTRUCTIONS	; Set the return value
	jmp		load.exit				; Exit the procedure

.success:
	mov		eax, LOAD_SUCCESS		; Set the success return value
	jmp		load.exit				; Exit the procedure

.exit:
	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller



instructionCount:
	push	ebp								; Store base pointer
	mov		ebp, esp						; Set base pointer to stack pointer
	sub		esp, 8							; Reserve 4 bytes on the stack for local variables (instruction count, current character)

	mov		dword [ebp - 4], 0				; Set initial instruction count to 0

.readingLoop:
	lea		eax, [ebp - 8]					; Store the current character's local variable effective address in register eax
	push	1
	push	eax
	push	dword [ebp + 8]					; Push the file descriptor
	call	sysRead							; Read a single byte from the file
	add		esp, 12							; Clear stack arguments

	cmp		eax, 0							; Check if the read operation read any byte
	je		instructionCount.exit			; Exit the procedure successfully when no bytes are left to be read

	cmp		byte [ebp - 8], '>'				; Check if the character read is '>'
	je		instructionCount.symbol			; Increment instruction count

	cmp		byte [ebp - 8], '<'				; Check if the character read is '<'
	je		instructionCount.symbol			; Increment instruction count

	cmp		byte [ebp - 8], '+'				; Check if the character read is '+'
	je		instructionCount.symbol			; Increment instruction count

	cmp		byte [ebp - 8], '-'				; Check if the character read is '-'
	je		instructionCount.symbol			; Increment instruction count

	cmp		byte [ebp - 8], '.'				; Check if the character read is '.'
	je		instructionCount.symbol			; Increment instruction count

	cmp		byte [ebp - 8], ','				; Check if the character read is ','
	je		instructionCount.symbol			; Increment instruction count

	cmp		byte [ebp - 8], '['				; Check if the character read is '['
	je		instructionCount.symbol			; Increment instruction count

	cmp		byte [ebp - 8], ']'				; Check if the character read is ']'
	je		instructionCount.symbol			; Increment instruction count

	jmp 	instructionCount.readingLoop	; Ignore the character read if it's not a valid symbol

.symbol:
	inc		dword [ebp - 4]					; Increment instruction count
	jmp		instructionCount.readingLoop	; Keep reading the file

.exit:
	mov		eax, dword [ebp - 4]			; Store count in eax to be used as return value

	mov		esp, ebp						; Clear stack
	pop		ebp								; Restore base pointer
	ret										; Return to caller



%endif