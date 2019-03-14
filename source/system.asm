%ifndef SYSTEM_ASM
%define SYSTEM_ASM

; System calls
SYS_EXIT	equ	1
SYS_READ	equ	3
SYS_WRITE	equ	4
SYS_OPEN	equ	5
SYS_CLOSE	equ	6
SYS_LSEEK	equ	19

; Status codes
EXIT_SUCCESS	equ	0
EXIT_FAILURE	equ	1

; Standard file descriptors
STDIN	equ	0
STDOUT	equ	1
STDERR	equ	2

; File flags
RDONLY	equ	0
WRONLY	equ	1
RDWR	equ	2

; File origin
SEEK_SET	equ	0
SEEK_CUR	equ	1
SEEK_END	equ	2

sysExit:
	push	ebp
	mov		ebp, esp

	mov	eax, SYS_EXIT
	mov	ebx, [ebp + 8]	; status code
	int	0x80

	mov		esp, ebp	; unreachable code
	pop		ebp			; unreachable code
	ret					; unreachable code

sysRead:
	push	ebp
	mov		ebp, esp

	push	ebx

	mov		eax, SYS_READ
	mov		ebx, [ebp + 8]	; file descriptor
	mov		ecx, [ebp + 12]	; destination buffer
	mov		edx, [ebp + 16]	; count
	int		0x80

	pop		ebx

	mov		esp, ebp
	pop		ebp
	ret

sysWrite:
	push	ebp
	mov		ebp, esp

	push	ebx

	mov		eax, SYS_WRITE
	mov		ebx, [ebp + 8]	; file descriptor
	mov		ecx, [ebp + 12]	; source buffer
	mov		edx, [ebp + 16]	; count
	int		0x80

	pop		ebx

	mov		esp, ebp
	pop		ebp
	ret

sysOpen:
	push	ebp
	mov		ebp, esp

	push	ebx

	mov		eax, SYS_OPEN
	mov		ebx, [ebp + 8]	; file name
	mov		ecx, [ebp + 12]	; flags
	mov		edx, [ebp + 16]	; mode
	int		0x80

	pop		ebx

	mov		esp, ebp
	pop		ebp
	ret

sysClose:
	push	ebp
	mov		ebp, esp

	push	ebx

	mov		eax, SYS_CLOSE
	mov		ebx, [ebp + 8]	; file descriptor
	int		0x80

	pop		ebx

	mov		esp, ebp
	pop		ebp
	ret

sysLSeek:
	push	ebp
	mov		ebp, esp

	push	ebx

	mov		eax, SYS_LSEEK
	mov		ebx, [ebp + 8]	; file descriptor
	mov		ecx, [ebp + 12]	; offset
	mov		edx, [ebp + 16]	; origin
	int		0x80

	pop		ebx

	mov		esp, ebp
	pop		ebp
	ret

%endif