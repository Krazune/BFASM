%ifndef LOADER_ASM
%define LOADER_ASM



%include "system.asm"



LOAD_SUCCESS	equ	0
INVALID_PATH	equ	-1



segment .text
load:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer
	sub		esp, 4					; Reserve 4 bytes on the stack for a local variable (file descriptor)

	push	0						; Mode is ignored on read only
	push	RDONLY
	push	dword [ebp + 8]			; File path received as argument
	call	sysOpen					; Open file
	add		esp, 12					; Clear stack arguments

	cmp		eax, 0					; Check if the file was open successfully
	jl		load.invalidPath		; Exit the procedure if the file was not open successfully

	mov		dword [ebp - 4], eax	; Store file descriptor

	push	dword [ebp - 4]
	call	sysClose				; Close the open file descriptor
	add		esp, 4					; Clear stack arguments

	jmp		load.success			; Exit the procedure successfully

.invalidPath:
	mov		eax, INVALID_PATH		; Set the failure return value
	jmp		load.exit				; Exit the procedure

.success:
	mov		eax, LOAD_SUCCESS		; Set the success return value
	jmp		load.exit				; Exit the procedure

.exit:
	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller



%endif