;	Description:
;		Some Linux system calls, and related defines.




%ifndef SYSTEM_ASM
%define SYSTEM_ASM




; System calls' values
SYS_EXIT				equ	1	; Terminate the calling process with exit status.
SYS_READ				equ	3	; Read from a file descriptor.
SYS_WRITE				equ	4	; Write to a file descriptor.
SYS_OPEN				equ	5	; Open and possibly create a file.
SYS_CLOSE				equ	6	; Close a file descriptor.
SYS_LSEEK				equ	19	; Reposition read/write file offset.
SYS_MMAP				equ	90	; Map files or devices into memory.

; Program exit status codes
SYS_EXIT_SUCCESS		equ	0	; Successful execution of a program.
SYS_EXIT_FAILURE		equ	1	; Unsuccessful execution of a program.

; Standard file descriptors
SYS_STDIN				equ	0	; Standard input stream.
SYS_STDOUT				equ	1	; Standard output stream.
SYS_STDERR				equ	2	; Standard error stream.

; File flags
SYS_RDONLY				equ	0	; File may be read.
SYS_WRONLY				equ	1	; File may be written.
SYS_RDWR				equ	2	; File may be read, and written.

; File origin
SYS_SEEK_SET			equ	0	; Offset starts at the beginning of the file.
SYS_SEEK_CUR			equ	1	; Offset starts at the current position.
SYS_SEEK_END			equ	2	; Offset starts at the end of the file.

; Map permissions
SYS_PROT_NONE			equ	0	; Mapping may not be accessed.
SYS_PROT_READ			equ	1	; Mapping may be read.
SYS_PROT_WRITE			equ	2	; Mapping may be written.
SYS_PROT_EXEC			equ	4	; Mapping may be executed.

; Map flags
SYS_MAP_SHARED			equ	1	; Changes are visible to other processes, and are carried through to the underlying file.
SYS_MAP_PRIVATE			equ	2	; Changes are not visible to other processes, and are not carried through to the underlying file.
SYS_MAP_SHARED_VALIDATE	equ	3	; Same as SYS_MAP_SHARED, but checks for unknown flags.
SYS_MAP_TYPE			equ	15	; Mask for type of mapping.
SYS_MAP_FIXED			equ	16	; Place the mapping at exactly the provided address.
SYS_MAP_ANONYMOUS		equ	32	; The mapping is not backed by any file. Its contents are initialized to zero.




;
;	Description:
;		Terminate the calling process with exit status.
;
;	Parameters:
;		Program exit status.
;
;	Return:
;		None.
;
;	Notes:
;		This procedure does not return to the caller.
;
sysExit:
	mov		eax, SYS_EXIT	; Set sys_exit system call number
	mov		ebx, [esp + 4]	; Use parameter as exit status
	int		0x80			; Kernel interrupt




;
;	Description:
;		Read from a file descriptor.
;
;	Parameters:
;		File descriptor.
;		Destination address.
;		Amount of bytes to be read.
;
;	Return:
;		On success, the number of bytes read is returned.
;		On error, -1 is returned.
;
;	Notes:
;		On success, the file position is advanced by the amount of bytes read.
;
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




;
;	Description:
;		Write to a file descriptor.
;
;	Parameters:
;		File descriptor.
;		Source address.
;		Amount of bytes to be written.
;
;	Return:
;		On success, the number of bytes written is returned.
;		On error, -1 is returned.
;
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




;
;	Description:
;		Open and possibly create a file.
;
;	Parameters:
;		File name.
;		Flags.
;		Mode.
;
;	Return:
;		On success, the file descriptor is returned.
;		On error, -1 is returned.
;
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




;
;	Description:
;		Close a file descriptor.
;
;	Parameters:
;		File descriptor.
;
;	Return:
;		On success, 0 is returned.
;		On error, -1 is returned.
;
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




;
;	Description:
;		Reposition read/write file offset.
;
;	Parameters:
;		File descriptor.
;		Byte offset.
;		Origin.
;
;	Return:
;		On success, the resulting offset location as measured in bytes from the beginning of the file is returned.
;		On error, -1 is returned.
;
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




;
;	Description:
;		Map files or devices into memory.
;
;	Parameters:
;		Memory map argument structure address.
;
;	Return:
;		On success, a pointer to the memory map is returned.
;		On error, -1 is returned.
;
sysMMap:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	push	ebx						; Store non-volatile register ebx

	mov		eax, SYS_MMAP			; Set sys_mmap system call number
	mov		ebx, [ebp + 8]			; Load argument struct address
	int		0x80					; Kernel interrupt

	pop		ebx						; Restore non-volatile register ebx

	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller




%endif