%ifndef SYSTEM_ASM
%define SYSTEM_ASM

; System calls
SYS_EXIT	equ	1

; Status codes
EXIT_SUCCESS	equ	0
EXIT_FAILURE	equ	1

sysExit:
	mov	eax, SYS_EXIT
	pop	ebx				; status code
	int	0x80

%endif