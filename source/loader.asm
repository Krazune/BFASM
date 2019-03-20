%ifndef LOADER_ASM
%define LOADER_ASM



%include "system.asm"



LOAD_SUCCESS		equ	0
INVALID_PATH		equ	-1
ZERO_INSTRUCTIONS	equ	-2
MEMORY_ERROR		equ	-3



segment .text
load:
	push	ebp											; Store base pointer
	mov		ebp, esp									; Set base pointer to stack pointer
	sub		esp, 36										; Reserve 4 bytes on the stack for local variables (file descriptor, instruction count, instructions address, memory map argument structure)

	push	0											; Mode is ignored on read only
	push	RDONLY
	push	dword [ebp + 8]								; File path received as argument
	call	sysOpen										; Open file
	add		esp, 12										; Clear stack arguments

	cmp		eax, 0										; Check if the file was open successfully
	jl		load.invalidPath							; Exit the procedure if the file was not open successfully

	mov		dword [ebp - 4], eax						; Store file descriptor

	push	dword [ebp - 4]								; Push file descriptor number
	call	instructionCount							; Count instructions
	add		esp, 4										; Clear stack arguments

	cmp		eax, 0										; Check if zero count
	je		load.zeroInstructions						; Exit procedure with zero instruction return value

	mov		dword [ebp - 8], eax						; Store instruction count

	lea		eax, [ebp - 16]								; Store the file offset's local variable effective address in register eax
	mov		dword [eax], 0								; Set file offeset to 0

	lea		eax, [ebp - 20]								; Store the file descriptor's local variable effective address in register eax
	mov		dword [eax], -1								; Set file offeset to -1

	lea		eax, [ebp - 24]								; Store the map flags' local variable effective address in register eax
	mov		dword [eax], MAP_PRIVATE | MAP_ANONYMOUS	; Set map flags to private, and anonymous

	lea		eax, [ebp - 28]								; Store the map protection's local variable effective address in register eax
	mov		dword [eax], PROT_READ | PROT_WRITE			; Set map protection to read, and write

	lea		eax, [ebp - 32]								; Store the map size's local variable effective address in register eax
	mov		ecx, dword [ebp - 8]						; Store instruction count in register ecx
	mov		dword [eax], ecx							; Set map size to instruction count

	lea		eax, [ebp - 36]								; Store the map adress's local variable effective address in register eax
	mov		dword [eax], 0								; Set map address to 0

	lea		eax, [ebp - 36]								; Store the memory map argument structure's local variable effective address in register eax

	push	eax											; Push memory map argument structure's address
	call	sysMMap										; Map memory
	add		esp, 4										; Clear stack arguments

	cmp		eax, -1										; Check if memory was mapped successfully
	je		load.memoryError							; Exit the procedure if the memory was not mapped successfully

	mov		dword [ebp - 12], eax						; Store the memory map address in local variable

	push	SEEK_SET
	push	0
	push	dword [ebp - 4]
	call	sysLSeek									; Rewind file
	add		esp, 12										; Clear stack arguments

	push	dword [ebp - 12]							; Push instruction memory map address
	push	dword [ebp - 4]								; Push file descriptor
	call	loadInstructions							; Load instructions
	add		esp, 8										; Clear stack arguments

	jmp		load.success								; Exit the procedure successfully

.invalidPath:
	mov		eax, INVALID_PATH							; Set the failure return value
	jmp		load.exit									; Exit the procedure

.zeroInstructions:
	push	dword [ebp - 4]								; Push file descriptor number
	call	sysClose									; Close the open file descriptor
	add		esp, 4										; Clear stack arguments

	mov		eax, ZERO_INSTRUCTIONS						; Set the return value
	jmp		load.exit									; Exit the procedure

.memoryError:
	push	dword [ebp - 4]								; Push file descriptor number
	call	sysClose									; Close the open file descriptor
	add		esp, 4										; Clear stack arguments

	mov		eax, MEMORY_ERROR							; Set the return value
	jmp		load.exit									; Exit the procedure

.success:
	push	dword [ebp - 4]								; Push file descriptor number
	call	sysClose									; Close the open file descriptor
	add		esp, 4										; Clear stack arguments

	mov		eax, LOAD_SUCCESS							; Set the success return value
	jmp		load.exit									; Exit the procedure

.exit:
	mov		esp, ebp									; Clear stack
	pop		ebp											; Restore base pointer
	ret													; Return to caller



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



loadInstructions:
	push	ebp								; Store base pointer
	mov		ebp, esp						; Set base pointer to stack pointer
	sub		esp, 4							; Reserve 4 bytes on the stack for a local variable (current character)

	mov		dword [ebp - 4], 0				; Set initial instruction count to 0

.readingLoop:
	lea		eax, [ebp - 4]					; Store the current character's local variable effective address in register eax
	push	1
	push	eax
	push	dword [ebp + 8]					; Push the file descriptor
	call	sysRead							; Read a single byte from the file
	add		esp, 12							; Clear stack arguments

	cmp		eax, 0							; Check if the read operation read any byte
	je		loadInstructions.exit			; Exit the procedure successfully when no bytes are left to be read

	cmp		byte [ebp - 4], '>'				; Check if the character read is '>'
	je		loadInstructions.symbol			; Store instruction

	cmp		byte [ebp - 4], '<'				; Check if the character read is '<'
	je		loadInstructions.symbol			; Store instruction

	cmp		byte [ebp - 4], '+'				; Check if the character read is '+'
	je		loadInstructions.symbol			; Store instruction

	cmp		byte [ebp - 4], '-'				; Check if the character read is '-'
	je		loadInstructions.symbol			; Store instruction

	cmp		byte [ebp - 4], '.'				; Check if the character read is '.'
	je		loadInstructions.symbol			; Store instruction

	cmp		byte [ebp - 4], ','				; Check if the character read is ','
	je		loadInstructions.symbol			; Store instruction

	cmp		byte [ebp - 4], '['				; Check if the character read is '['
	je		loadInstructions.symbol			; Store instruction

	cmp		byte [ebp - 4], ']'				; Check if the character read is ']'
	je		loadInstructions.symbol			; Store instruction

	jmp 	loadInstructions.readingLoop	; Ignore the character read if it's not a valid symbol

.symbol:
	mov		al, byte [ebp - 4]				; Store current character in register al
	mov		ecx, dword [ebp + 12]			; Store current instruction address in register ecx
	mov		byte [ecx], al					; Store current character in current instruction address

	inc		dword [ebp + 12]				; Increment instruction count
	jmp		loadInstructions.readingLoop	; Keep reading the file

.exit:
	mov		esp, ebp						; Clear stack
	pop		ebp								; Restore base pointer
	ret										; Return to caller



%endif