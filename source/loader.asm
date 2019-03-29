;	Description:
;		Reads brainfuck instructions from file, and stores it in the program's memory.




%ifndef LOADER_ASM
%define LOADER_ASM




%include "system.asm"




LOAD_SUCCESS			equ	0
LOAD_INVALID_PATH		equ	-1
ZERO_INSTRUCTIONS		equ	-2
MEMORY_ERROR			equ	-3
MISSING_LEFT_BRACKET	equ	-4
MISSING_RIGHT_BRACKET	equ	-5




segment .text
load:
	push	ebp														; Store base pointer
	mov		ebp, esp												; Set base pointer to stack pointer
	sub		esp, 36													; Reserve 4 bytes on the stack for local variables (file descriptor, instruction count, instructions address, memory map argument structure)

	push	0														; Mode is ignored on read only
	push	SYS_RDONLY
	push	dword [ebp + 8]											; File path received as argument
	call	sysOpen													; Open file
	add		esp, 12													; Clear stack arguments

	cmp		eax, -1													; Check if the file was open successfully
	je		load.invalidPath										; Exit the procedure if the file was not open successfully

	mov		dword [ebp - 4], eax									; Store file descriptor

	push	eax														; Push file descriptor number
	call	instructionCount										; Count instructions
	add		esp, 4													; Clear stack arguments

	cmp		eax, 0													; Check if zero count
	je		load.zeroInstructions									; Exit procedure with zero instruction return value

	mov		dword [ebp - 8], eax									; Store instruction count

	mov		dword [ebp - 36], 0										; Set map address to 0

	mov		ecx, dword [ebp - 8]									; Store instruction count in register ecx
	mov		dword [ebp - 32], ecx									; Set map size to instruction count

	mov		dword [ebp - 28], SYS_PROT_READ | SYS_PROT_WRITE		; Set map protection to read, and write

	mov		dword [ebp - 24], SYS_MAP_PRIVATE | SYS_MAP_ANONYMOUS

	mov		dword [ebp - 20], -1									; Set file descriptor to -1

	mov		dword [ebp - 16], 0										; Set file offeset to 0

	lea		eax, [ebp - 36]											; Store the memory map argument structure's local variable effective address in register eax

	push	eax														; Push memory map argument structure's address
	call	sysMMap													; Map memory
	add		esp, 4													; Clear stack arguments

	cmp		eax, -1													; Check if memory was mapped successfully
	je		load.memoryError										; Exit the procedure if the memory was not mapped successfully

	mov		dword [ebp - 12], eax									; Store the memory map address in local variable

	push	SYS_SEEK_SET
	push	0
	push	dword [ebp - 4]
	call	sysLSeek												; Rewind file
	add		esp, 12													; Clear stack arguments

	push	dword [ebp - 12]										; Push instruction memory map address
	push	dword [ebp - 4]											; Push file descriptor
	call	loadInstructions										; Load instructions
	add		esp, 8													; Clear stack arguments

	cmp		eax, MISSING_LEFT_BRACKET								; Check for missing left bracket return value
	je		load.missingLeftBracket									; Exit procedure with error return value on missing bracket

	cmp		eax, MISSING_RIGHT_BRACKET								; Check for missing right bracket return value
	je		load.missingRightBracket								; Exit procedure with error return value on missing bracket

	mov		eax, dword [ebp + 12]									; Store instructions' address parameter in register eax
	mov		ecx, dword [ebp - 12]									; Store instructions' address' local variable in register ecx
	mov		dword [eax], ecx										; Store instructions' address in output parameter

	mov		eax, dword [ebp + 16]									; Store instruction count parameter in register eax
	mov		ecx, dword [ebp - 8]									; Store instruction count local variable in register ecx
	mov		dword [eax], ecx										; Store instruction count in output parameter

	jmp		load.success											; Exit the procedure successfully

.invalidPath:
	mov		eax, LOAD_INVALID_PATH									; Set the failure return value
	jmp		load.exit												; Exit the procedure

.zeroInstructions:
	mov		eax, ZERO_INSTRUCTIONS									; Set the return value
	jmp		load.closeAndExit

.memoryError:
	mov		eax, MEMORY_ERROR										; Set the return value
	jmp		load.closeAndExit

.missingLeftBracket:
	mov		eax, MISSING_LEFT_BRACKET								; Set the return value
	jmp		load.closeAndExit

.missingRightBracket:
	mov		eax, MISSING_RIGHT_BRACKET								; Set the return value
	jmp		load.closeAndExit

.success:
	mov		eax, LOAD_SUCCESS										; Set the success return value
	jmp		load.closeAndExit

.closeAndExit:
	push	eax

	push	dword [ebp - 4]											; Push file descriptor number
	call	sysClose												; Close the open file descriptor
	add		esp, 4													; Clear stack arguments

	pop		eax

.exit:
	mov		esp, ebp												; Clear stack
	pop		ebp														; Restore base pointer
	ret																; Return to caller




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
	push	ebp										; Store base pointer
	mov		ebp, esp								; Set base pointer to stack pointer
	sub		esp, 8									; Reserve 8 bytes on the stack for local variables (nesting level, and current character)

	mov		dword [ebp - 4], 0						; Set initial nesting level to 0

.readingLoop:
	lea		eax, [ebp - 8]							; Store the current character's local variable effective address in register eax
	push	1
	push	eax
	push	dword [ebp + 8]							; Push the file descriptor
	call	sysRead									; Read a single byte from the file
	add		esp, 12									; Clear stack arguments

	cmp		eax, 0									; Check if the read operation read any byte
	je		loadInstructions.checkNesting			; Check nesting level if no byte was read

	cmp		byte [ebp - 8], '>'						; Check if the character read is '>'
	je		loadInstructions.symbol					; Store instruction

	cmp		byte [ebp - 8], '<'						; Check if the character read is '<'
	je		loadInstructions.symbol					; Store instruction

	cmp		byte [ebp - 8], '+'						; Check if the character read is '+'
	je		loadInstructions.symbol					; Store instruction

	cmp		byte [ebp - 8], '-'						; Check if the character read is '-'
	je		loadInstructions.symbol					; Store instruction

	cmp		byte [ebp - 8], '.'						; Check if the character read is '.'
	je		loadInstructions.symbol					; Store instruction

	cmp		byte [ebp - 8], ','						; Check if the character read is ','
	je		loadInstructions.symbol					; Store instruction

	cmp		byte [ebp - 8], '['						; Check if the character read is '['
	je		loadInstructions.leftBracket			; Process left bracket

	cmp		byte [ebp - 8], ']'						; Check if the character read is ']'
	je		loadInstructions.rightBracket			; Process left bracket

	jmp 	loadInstructions.readingLoop			; Ignore the character read if it's not a valid symbol

.symbol:
	mov		al, byte [ebp - 8]						; Store current character in register al
	mov		ecx, dword [ebp + 12]					; Store current instruction address in register ecx
	mov		byte [ecx], al							; Store current character in current instruction address

	inc		dword [ebp + 12]						; Increment instruction count
	jmp		loadInstructions.readingLoop			; Keep reading the file

.leftBracket:
	inc		dword [ebp - 4]							; Increment nesting level
	jmp		loadInstructions.symbol					; Keep reading the file

.rightBracket:
	dec		dword [ebp - 4]							; Decrement nesting level

	cmp		dword [ebp - 4], 0						; Check if nesting level is below 0
	jl		loadInstructions.missingLeftBracket		; Exit the procedure with error return value if negative nesting level

	jmp		loadInstructions.symbol					; Process symbol

.checkNesting:
	cmp		dword [ebp - 4], 0						; Check if nesting is 0
	je		loadInstructions.success				; Exit the procedure successfully if nesting level is 0

	jmp		loadInstructions.missingRightBracket	; Exit the procedure with error return value nesting level is greater than 0

.missingLeftBracket:
	mov		eax, MISSING_LEFT_BRACKET				; Set return value
	jmp		loadInstructions.exit					; Exit procedure

.missingRightBracket:
	mov		eax, MISSING_RIGHT_BRACKET				; Set return value
	jmp		loadInstructions.exit					; Exit procedure

.success:
	mov		eax, LOAD_SUCCESS						; Set return value

.exit:
	mov		esp, ebp								; Clear stack
	pop		ebp										; Restore base pointer
	ret												; Return to caller




%endif