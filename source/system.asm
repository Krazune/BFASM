%ifndef SYSTEM_ASM
%define SYSTEM_ASM

; System calls
SYS_EXIT	equ	1
SYS_READ	equ	3
SYS_WRITE	equ	4

; Status codes
EXIT_SUCCESS	equ	0
EXIT_FAILURE	equ	1

; Standard file descriptors
STDIN	equ	0
STDOUT	equ	1
STDERR	equ	2

sysExit:
	mov	eax, SYS_EXIT
	pop	ebx				; status code
	int	0x80

sysRead:
	enter	0, 0

	push	ebx

	mov		eax, SYS_READ
	mov		ebx, [ebp + 8]	; file descriptor
	mov		ecx, [ebp + 12]	; destination buffer
	mov		edx, [ebp + 16]	; count
	int		0x80

	pop		ebx

	leave
	ret

sysWrite:
	enter	0, 0

	push	ebx

	mov		eax, SYS_WRITE
	mov		ebx, [ebp + 8]	; file descriptor
	mov		ecx, [ebp + 12]	; source buffer
	mov		edx, [ebp + 16]	; count
	int		0x80

	pop		ebx

	leave
	ret

%endif