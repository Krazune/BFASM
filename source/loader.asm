%ifndef LOADER_ASM
%define LOADER_ASM



%include "system.asm"


segment .text
load:
	push	ebp			; Store base pointer
	mov		ebp, esp	; Set base pointer to stack pointer

	mov		esp, ebp	; Clear stack
	pop		ebp			; Restore base pointer
	ret					; Return to caller



%endif