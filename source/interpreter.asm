%ifndef INTERPRETER_ASM
%define INTERPRETER_ASM

%include "system.asm"

NO_ERROR		equ	0
GENERAL_ERROR	equ	1

segment .bss
	inputFileDescriptor	resd	1

segment .text
interprete:
	enter	0, 0

	push	0777
	push	RDONLY
	push	dword [ebp + 8]	; Input file path
	call	sysOpen			; Open file
	add		esp, 12

	cmp		eax, 0				; Check if file was open successfully
	jl		interprete.failure

	mov		[inputFileDescriptor], eax	; Store file descriptor

	; Interprete file

	jmp		interprete.success

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

%endif