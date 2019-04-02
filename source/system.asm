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
SYS_PROT_RDWR			equ	3	; Mapping may be read, and written.
SYS_PROT_EXEC			equ	4	; Mapping may be executed.

; Map flags
SYS_MAP_SHARED			equ	1	; Changes are visible to other processes, and are carried through to the underlying file.
SYS_MAP_PRIVATE			equ	2	; Changes are not visible to other processes, and are not carried through to the underlying file.
SYS_MAP_SHARED_VALIDATE	equ	3	; Same as SYS_MAP_SHARED, but checks for unknown flags.
SYS_MAP_TYPE			equ	15	; Mask for type of mapping.
SYS_MAP_FIXED			equ	16	; Place the mapping at exactly the provided address.
SYS_MAP_ANONYMOUS		equ	32	; The mapping is not backed by any file. Its contents are initialized to zero.
SYS_MAP_PRIVANON		equ	34	; Changes are not visible to other processes, and there is no backing file.




segment .data
	sys_errno	dd	0	; Error number returned from the system calls.




segment .text
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
	mov		eax, SYS_EXIT	; Load the system call value.
	mov		ebx, [esp + 4]	; Load the program's exit status.
	int		0x80			; Invoke the system call.




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
;		On error, sets sys_errno with the error number.
;
sysRead:
	push	ebp					; Store the caller's base pointer.
	mov		ebp, esp			; Set the current procedure's base pointer.

	push	ebx					; Store the non-volatile register ebx.

	mov		eax, SYS_READ		; Load the system call value.
	mov		ebx, [ebp + 8]		; Load the file descriptor to read from.
	mov		ecx, [ebp + 12]		; Load the destination address.
	mov		edx, [ebp + 16]		; Load the amount of bytes to be read.
	int		0x80				; Invoke the system call.

	cmp		eax, 0				; Compare the system call's return value with 0.
	jge		sysRead.exit		; Exit the procedure if the return value is not negative (successful return value).

	cmp		eax, -4095			; Compare the system call's return value with the lowest error value.
	jl		sysRead.exit		; Exit the procedure if the return value is lower than -4095 (successful return value).

	mov		[sys_errno], eax	; Set sys_errno to the system call's error number.
	mov		eax, -1				; Set the procedure's return value to -1.

.exit:
	pop		ebx					; Restore the non-volatile register ebx.

	mov		esp, ebp			; Clear stack.
	pop		ebp					; Restore caller's base pointer.
	ret							; Return to caller.




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
;	Notes:
;		On error, sets sys_errno with the error number.
;
sysWrite:
	push	ebp					; Store the caller's base pointer.
	mov		ebp, esp			; Set the current procedure's base pointer.

	push	ebx					; Store the non-volatile register ebx.

	mov		eax, SYS_WRITE		; Load the system call value.
	mov		ebx, [ebp + 8]		; Load the file descriptor to write to.
	mov		ecx, [ebp + 12]		; Load the source address.
	mov		edx, [ebp + 16]		; Load the amount of bytes to be written.
	int		0x80				; Invoke the system call.

	cmp		eax, 0				; Compare the system call's return value with 0.
	jge		sysWrite.exit		; Exit the procedure if the return value is not negative (successful return value).

	cmp		eax, -4095			; Compare the system call's return value with the lowest error value.
	jl		sysWrite.exit		; Exit the procedure if the return value is lower than -4095 (successful return value).

	mov		[sys_errno], eax	; Set sys_errno to the system call's error number.
	mov		eax, -1				; Set the procedure's return value to -1.

.exit:
	pop		ebx					; Restore the non-volatile register ebx.

	mov		esp, ebp			; Clear stack.
	pop		ebp					; Restore caller's base pointer.
	ret							; Return to caller.




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
;	Notes:
;		On error, sets sys_errno with the error number.
;
sysOpen:
	push	ebp					; Store the caller's base pointer.
	mov		ebp, esp			; Set the current procedure's base pointer.

	push	ebx					; Store the non-volatile register ebx.

	mov		eax, SYS_OPEN		; Load the system call value.
	mov		ebx, [ebp + 8]		; Load the file name.
	mov		ecx, [ebp + 12]		; Load the flags.
	mov		edx, [ebp + 16]		; Load the mode.
	int		0x80				; Invoke the system call.

	cmp		eax, 0				; Compare the system call's return value with 0.
	jge		sysOpen.exit		; Exit the procedure if the return value is not negative (successful return value).

	cmp		eax, -4095			; Compare the system call's return value with the lowest error value.
	jl		sysOpen.exit		; Exit the procedure if the return value is lower than -4095 (successful return value).

	mov		[sys_errno], eax	; Set sys_errno to the system call's error number.
	mov		eax, -1				; Set the procedure's return value to -1.

.exit:
	pop		ebx					; Restore the non-volatile register ebx.

	mov		esp, ebp			; Clear stack.
	pop		ebp					; Restore caller's base pointer.
	ret							; Return to caller.




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
;	Notes:
;		On error, sets sys_errno with the error number.
;
sysClose:
	push	ebp					; Store the caller's base pointer.
	mov		ebp, esp			; Set the current procedure's base pointer.

	push	ebx					; Store the non-volatile register ebx.

	mov		eax, SYS_CLOSE		; Load the system call value.
	mov		ebx, [ebp + 8]		; Load the file descriptor to be closed.
	int		0x80				; Invoke the system call.

	cmp		eax, 0				; Compare the system call's return value with 0.
	jge		sysClose.exit		; Exit the procedure if the return value is not negative (successful return value).

	cmp		eax, -4095			; Compare the system call's return value with the lowest error value.
	jl		sysClose.exit		; Exit the procedure if the return value is lower than -4095 (successful return value).

	mov		[sys_errno], eax	; Set sys_errno to the system call's error number.
	mov		eax, -1				; Set the procedure's return value to -1.

.exit:
	pop		ebx					; Restore the non-volatile register ebx.

	mov		esp, ebp			; Clear stack.
	pop		ebp					; Restore caller's base pointer.
	ret							; Return to caller.




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
;	Notes:
;		On error, sets sys_errno with the error number.
;
sysLSeek:
	push	ebp					; Store the caller's base pointer.
	mov		ebp, esp			; Set the current procedure's base pointer.

	push	ebx					; Store the non-volatile register ebx.

	mov		eax, SYS_LSEEK		; Load the system call value.
	mov		ebx, [ebp + 8]		; Load the file descriptor to seek.
	mov		ecx, [ebp + 12]		; Load the byte offset.
	mov		edx, [ebp + 16]		; Load the origin.
	int		0x80				; Invoke the system call.

	cmp		eax, 0				; Compare the system call's return value with 0.
	jge		sysLSeek.exit		; Exit the procedure if the return value is not negative (successful return value).

	cmp		eax, -4095			; Compare the system call's return value with the lowest error value.
	jl		sysLSeek.exit		; Exit the procedure if the return value is lower than -4095 (successful return value).

	mov		[sys_errno], eax	; Set sys_errno to the system call's error number.
	mov		eax, -1				; Set the procedure's return value to -1.

.exit:
	pop		ebx					; Restore the non-volatile register ebx.

	mov		esp, ebp			; Clear stack.
	pop		ebp					; Restore caller's base pointer.
	ret							; Return to caller.




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
;	Notes:
;		On error, sets sys_errno with the error number.
;
sysMMap:
	push	ebp					; Store the caller's base pointer.
	mov		ebp, esp			; Set the current procedure's base pointer.

	push	ebx					; Store the non-volatile register ebx.

	mov		eax, SYS_MMAP		; Load the system call value.
	mov		ebx, [ebp + 8]		; Load the argument structure address.
	int		0x80				; Invoke the system call.

	cmp		eax, 0				; Compare the system call's return value with 0.
	jge		sysMMap.exit		; Exit the procedure if the return value is not negative (successful return value).

	cmp		eax, -4095			; Compare the system call's return value with the lowest error value.
	jl		sysMMap.exit		; Exit the procedure if the return value is lower than -4095 (successful return value).

	mov		[sys_errno], eax	; Set sys_errno to the system call's error number.
	mov		eax, -1				; Set the procedure's return value to -1.

.exit:
	pop		ebx					; Restore the non-volatile register ebx.

	mov		esp, ebp			; Clear stack.
	pop		ebp					; Restore caller's base pointer.
	ret							; Return to caller.




%endif