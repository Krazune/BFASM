;	Description:
;		Some Linux system calls, and related defines.




%ifndef SYSTEM_ASM
%define SYSTEM_ASM




; System calls
SYS_EXIT			equ	1
SYS_READ			equ	3
SYS_WRITE			equ	4
SYS_OPEN			equ	5
SYS_CLOSE			equ	6
SYS_LSEEK			equ	19
SYS_MMAP			equ	90

; Status codes
EXIT_SUCCESS		equ	0
EXIT_FAILURE		equ	1

; Standard file descriptors
STDIN				equ	0
STDOUT				equ	1
STDERR				equ	2

; File flags
RDONLY				equ	0
WRONLY				equ	1
RDWR				equ	2

; File origin
SEEK_SET			equ	0
SEEK_CUR			equ	1
SEEK_END			equ	2

; Map protection
PROT_NONE			equ	0
PROT_READ			equ	1
PROT_WRITE			equ	2
PROT_EXEC			equ	4

; Map flags
MAP_SHARED			equ	1
MAP_PRIVATE			equ	2
MAP_SHARED_VALIDATE	equ	3
MAP_TYPE			equ	15
MAP_FIXED			equ	16
MAP_ANONYMOUS		equ	32




sysExit:
	push	ebp				; Store base pointer
	mov		ebp, esp		; Set base pointer to stack pointer

	mov		eax, SYS_EXIT	; Set sys_exit system call number
	mov		ebx, [ebp + 8]	; Use parameter as exit status
	int		0x80			; Kernel interrupt

	mov		esp, ebp		; Unreachable code
	pop		ebp				; Unreachable code
	ret						; Unreachable code




sysRead:
	push	ebp				; Store base pointer
	mov		ebp, esp		; Set base pointer to stack pointer

	push	ebx				; Store non-volatile register ebx

	mov		eax, SYS_READ	; Set sys_read system call number
	mov		ebx, [ebp + 8]	; File descriptor to read from
	mov		ecx, [ebp + 12]	; Destination buffer
	mov		edx, [ebp + 16]	; Amount of bytes to be read
	int		0x80			; Kernel interrupt

	pop		ebx				; Restore non-volatile register ebx

	mov		esp, ebp		; Clear stack
	pop		ebp				; Restore base pointer
	ret						; Return to caller




sysWrite:
	push	ebp				; Store base pointer
	mov		ebp, esp		; Set base pointer to stack pointer

	push	ebx				; Store non-volatile register ebx

	mov		eax, SYS_WRITE	; Set sys_write system call number
	mov		ebx, [ebp + 8]	; File descriptor to write to
	mov		ecx, [ebp + 12]	; Source buffer
	mov		edx, [ebp + 16]	; Amount of bytes to be written
	int		0x80			; Kernel interrupt

	pop		ebx				; Restore non-volatile register ebx

	mov		esp, ebp		; Clear stack
	pop		ebp				; Restore base pointer
	ret						; Return to caller




sysOpen:
	push	ebp				; Store base pointer
	mov		ebp, esp		; Set base pointer to stack pointer

	push	ebx				; Store non-volatile register ebx

	mov		eax, SYS_OPEN	; Set sys_open system call number
	mov		ebx, [ebp + 8]	; File name
	mov		ecx, [ebp + 12]	; Flags
	mov		edx, [ebp + 16]	; Mode
	int		0x80			; Kernel interrupt

	pop		ebx				; Restore non-volatile register ebx

	mov		esp, ebp		; Clear stack
	pop		ebp				; Restore base pointer
	ret						; Return to caller




sysClose:
	push	ebp				; Store base pointer
	mov		ebp, esp		; Set base pointer to stack pointer

	push	ebx				; Store non-volatile register ebx

	mov		eax, SYS_CLOSE	; Set sys_close system call number
	mov		ebx, [ebp + 8]	; File descriptor to be closed
	int		0x80			; Kernel interrupt

	pop		ebx				; Restore non-volatile register ebx

	mov		esp, ebp		; Clear stack
	pop		ebp				; Restore base pointer
	ret						; Return to caller




sysLSeek:
	push	ebp				; Store base pointer
	mov		ebp, esp		; Set base pointer to stack pointer

	push	ebx				; Store non-volatile register ebx

	mov		eax, SYS_LSEEK	; Set sys_lseek system call number
	mov		ebx, [ebp + 8]	; File descriptor to seek
	mov		ecx, [ebp + 12]	; Byte offset
	mov		edx, [ebp + 16]	; Origin
	int		0x80			; Kernel interrupt

	pop		ebx				; Restore non-volatile register ebx

	mov		esp, ebp		; Clear stack
	pop		ebp				; Restore base pointer
	ret						; Return to caller




sysMMap:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	push	ebx						; Store non-volatile register ebx

	mov		eax, SYS_MMAP			; Set sys_mmap system call number
	mov		ebx, dword [ebp + 8]	; Load argument struct address
	int		0x80					; Kernel interrupt

	pop		ebx						; Restore non-volatile register ebx

	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller




%endif