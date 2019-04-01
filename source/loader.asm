;	Description:
;		Reads brainfuck instructions from file, and stores it in the program's memory.




%ifndef LOADER_ASM
%define LOADER_ASM




%include "system.asm"




LOAD_SUCCESS			equ	0	; Instructions loaded successfully.
LOAD_INVALID_PATH		equ	-1	; Invalid path given.
ZERO_INSTRUCTIONS		equ	-2	; No instructions in the input file.
MEMORY_ERROR			equ	-3	; Dynamic memory error.
MISSING_LEFT_BRACKET	equ	-4	; Missing left bracket.
MISSING_RIGHT_BRACKET	equ	-5	; Missing right bracket.




segment .text
;
;	Description:
;		Load instructions from file, into the program's memory.
;
;	Parameters:
;		File name.
;		Instructions' destination address.
;		Instruction count's address.
;
;	Local variables:
;		File descriptor.
;		Instruction count's address.
;		Instructions' memory map address.
;		File offset (part of the memory map argument structure).
;		File descriptor (part of the memory map argument structure).
;		Map flags (part of the memory map argument structure).
;		Map protection (part of the memory map argument structure).
;		Map size (part of the memory map argument structure).
;		Map address (part of the memory map argument structure).
;
;	Return:
;		On success, LOAD_SUCCESS is returned.
;		On invalid path, LOAD_INVALID_PATH is returned.
;		On zero instructions in input file, ZERO_INSTRUCTIONS is returned.
;		On dynamic memory error, MEMORY_ERROR is returned.
;		On missing left bracket, MISSING_LEFT_BRACKET is returned.
;		On missing right bracket, MISSING_RIGHT_BRACKET is returned.
;
;	Notes:
;		The instructions' memory map address, and the instruction count are passed to the caller using the parameters.
;
load:
	push	ebp														; Store the caller's base pointer.
	mov		ebp, esp												; Set the current procedure's base pointer.
	sub		esp, 36													; Reserve space for local variables (file descriptor, instruction count, instructions address, memory map argument structure).

	push	0														; Push mode (ignored on read only).
	push	SYS_RDONLY												; Push flags.
	push	dword [ebp + 8]											; Push the file name.
	call	sysOpen													; Open the file.
	add		esp, 12													; Clear the stack arguments.

	cmp		eax, -1													; Compare the system call return value with -1.
	je		load.invalidPath										; Exit the procedure, if the file was not open successfully.

	mov		dword [ebp - 4], eax									; Store the file descriptor.

	push	eax														; Push the file descriptor.
	call	instructionCount										; Count the instructions in the file.
	add		esp, 4													; Clear the stack arguments.

	cmp		eax, 0													; Compare the instruction count with 0.
	je		load.zeroInstructions									; Exit the procedure, if 0 instructions.

	mov		dword [ebp - 8], eax									; Store the instruction count.

	mov		dword [ebp - 16], 0										; Set the file offeset to 0 (ignored without a file).

	mov		dword [ebp - 20], -1									; Set the file descriptor to -1 (map not backed by any file).

	mov		dword [ebp - 24], SYS_MAP_PRIVATE | SYS_MAP_ANONYMOUS	; Set the map flags.

	mov		dword [ebp - 28], SYS_PROT_READ | SYS_PROT_WRITE		; Set the map protection.

	mov		ecx, dword [ebp - 8]									; Store the instruction count in ecx.
	mov		dword [ebp - 32], ecx									; Set the map size to the instruction count.

	mov		dword [ebp - 36], 0										; Set the map address to 0 (let the kernel choose the address).

	lea		eax, [ebp - 36]											; Store the memory map argument structure's address in eax.

	push	eax														; Push the memory map argument structure's address.
	call	sysMMap													; Map memory.
	add		esp, 4													; Clear the stack arguments.

	cmp		eax, -1													; Compare the system call return value with -1.
	je		load.memoryError										; Exit the procedure if the memory was not mapped successfully.

	mov		dword [ebp - 12], eax									; Store the memory map address.

	push	SYS_SEEK_SET											; Push the file origin.
	push	0														; Push the offset.
	push	dword [ebp - 4]											; Push the file descriptor.
	call	sysLSeek												; Rewind the file.
	add		esp, 12													; Clear the stack arguments.

	push	dword [ebp - 12]										; Push the instruction memory map's address.
	push	dword [ebp - 4]											; Push the file descriptor.
	call	loadInstructions										; Load instructions.
	add		esp, 8													; Clear the stack arguments.

	cmp		eax, MISSING_LEFT_BRACKET								; Compare the procedure's return value with the missing left bracket return value.
	je		load.missingLeftBracket									; Exit procedure with error return value if missing left bracket.

	cmp		eax, MISSING_RIGHT_BRACKET								; Compare the procedure's return value with the missing right bracket return value.
	je		load.missingRightBracket								; Exit procedure with error return value if missing right bracket.

	mov		eax, dword [ebp + 12]									; Store the instructions' parameter's address in eax.
	mov		ecx, dword [ebp - 12]									; Store the instructions' address in ecx.
	mov		dword [eax], ecx										; Store the instructions' address in the instructions' output parameter.

	mov		eax, dword [ebp + 16]									; Store the instruction count's parameter's address in eax.
	mov		ecx, dword [ebp - 8]									; Store the instruction count's address in ecx.
	mov		dword [eax], ecx										; Store the instruction count in the instruction count's output parameter.

	jmp		load.success											; Exit the procedure successfully.

.invalidPath:
	mov		eax, LOAD_INVALID_PATH									; Set the error return value.
	jmp		load.exit												; Exit the procedure.

.zeroInstructions:
	mov		eax, ZERO_INSTRUCTIONS									; Set the success return value.
	jmp		load.closeAndExit										; Close file and exit the procedure.

.memoryError:
	mov		eax, MEMORY_ERROR										; Set the error return value.
	jmp		load.closeAndExit										; Close file and exit the procedure.

.missingLeftBracket:
	mov		eax, MISSING_LEFT_BRACKET								; Set the error return value.
	jmp		load.closeAndExit										; Close file and exit the procedure.

.missingRightBracket:
	mov		eax, MISSING_RIGHT_BRACKET								; Set the error return value.
	jmp		load.closeAndExit										; Close file and exit the procedure.

.success:
	mov		eax, LOAD_SUCCESS										; Set the success return value.
	jmp		load.closeAndExit										; Close file and exit the procedure.

.closeAndExit:
	push	eax														; Store the error return value.

	push	dword [ebp - 4]											; Push the file descriptor.
	call	sysClose												; Close the file.
	add		esp, 4													; Clear the stack arguments.

	pop		eax														; Restore the error return value.

.exit:
	mov		esp, ebp												; Clear stack.
	pop		ebp														; Restore caller's base pointer.
	ret																; Return to caller.




;
;	Description:
;		Count the instructions in the file.
;
;	Parameters:
;		File descriptor.
;
;	Local variables:
;		Instruction count.
;		Last character read from file.
;
;	Return:
;		The instruction count is returned.
;
;	Notes:
;		Assumes that the file descriptor is valid.
;
instructionCount:
	push	ebp								; Store the caller's base pointer.
	mov		ebp, esp						; Set the current procedure's base pointer.
	sub		esp, 8							; Reserve space for local variables (instruction count, current character).

	mov		dword [ebp - 4], 0				; Set initial instruction count to 0.

.readingLoop:
	lea		eax, [ebp - 8]					; Store the current character's address in eax.

	push	1								; Push the amount of bytes to be read.
	push	eax								; Push the current character's address.
	push	dword [ebp + 8]					; Push the file descriptor.
	call	sysRead							; Read 1 byte from the file.
	add		esp, 12							; Clear the stack arguments.

	cmp		eax, 0							; Compare the character read with 0.
	je		instructionCount.exit			; Exit the procedure, if no characters left to be read.

	cmp		byte [ebp - 8], '>'				; Compare the character read with '>'.
	je		instructionCount.symbol			; Increment the instruction count, if the character read is '>'.

	cmp		byte [ebp - 8], '<'				; Compare the character read with '<'.
	je		instructionCount.symbol			; Increment the instruction count, if the character read is '<'.

	cmp		byte [ebp - 8], '+'				; Compare the character read with '+'.
	je		instructionCount.symbol			; Increment the instruction count, if the character read is '+'.

	cmp		byte [ebp - 8], '-'				; Compare the character read with '-'.
	je		instructionCount.symbol			; Increment the instruction count, if the character read is '-'.

	cmp		byte [ebp - 8], '.'				; Compare the character read with '.'.
	je		instructionCount.symbol			; Increment the instruction count, if the character read is '.'.

	cmp		byte [ebp - 8], ','				; Compare the character read with ','.
	je		instructionCount.symbol			; Increment the instruction count, if the character read is ','.

	cmp		byte [ebp - 8], '['				; Compare the character read with '['.
	je		instructionCount.symbol			; Increment the instruction count, if the character read is '['.

	cmp		byte [ebp - 8], ']'				; Compare the character read with ']'.
	je		instructionCount.symbol			; Increment the instruction count, if the character read is ']'.

	jmp 	instructionCount.readingLoop	; Ignore the character that was read, if it's not a valid instruction.

.symbol:
	inc		dword [ebp - 4]					; Increment the instruction count.
	jmp		instructionCount.readingLoop	; Keep reading the file.

.exit:
	mov		eax, dword [ebp - 4]			; Set the procedure's return value to the instruction count.

	mov		esp, ebp						; Clear stack.
	pop		ebp								; Restore caller's base pointer.
	ret										; Return to caller.




;
;	Description:
;		Read instructions from file, validate them, and load them into the program's memory.
;
;	Parameters:
;		File descriptor.
;		Instructions' destination address.
;
;	Local variables:
;		Bracket nesting level.
;		Last character read from file.
;
;	Return:
;		On success, LOAD_SUCCESS is returned.
;		On missing left bracket, MISSING_LEFT_BRACKET is returned.
;		On missing right bracket, MISSING_RIGHT_BRACKET is returned.
;
;	Notes:
;		Assumes that the file descriptor is valid, the destination memory is already mapped, and there is enough space to load all instructions.
;
loadInstructions:
	push	ebp										; Store the caller's base pointer.
	mov		ebp, esp								; Set the current procedure's base pointer.
	sub		esp, 8									; Reserve space for local variables (nesting level, current character).

	mov		dword [ebp - 4], 0						; Set initial nesting level to 0.

.readingLoop:
	lea		eax, [ebp - 8]							; Store the current character's address in eax.

	push	1										; Push the amount of bytes to be read.
	push	eax										; Push the current character's address.
	push	dword [ebp + 8]							; Push the file descriptor.
	call	sysRead									; Read 1 byte from the file.
	add		esp, 12									; Clear the stack arguments.

	cmp		eax, 0									; Compare the character read with 0.
	je		loadInstructions.checkNesting			; Validate nesting level, if no characters left to be read.

	cmp		byte [ebp - 8], '>'						; Compare the character read with '>'.
	je		loadInstructions.symbol					; Load instruction, if the character read is '>'.

	cmp		byte [ebp - 8], '<'						; Compare the character read with '<'.
	je		loadInstructions.symbol					; Load instruction, if the character read is '<'.

	cmp		byte [ebp - 8], '+'						; Compare the character read with '+'.
	je		loadInstructions.symbol					; Load instruction, if the character read is '+'.

	cmp		byte [ebp - 8], '-'						; Compare the character read with '-'.
	je		loadInstructions.symbol					; Load instruction, if the character read is '-'.

	cmp		byte [ebp - 8], '.'						; Compare the character read with '.'.
	je		loadInstructions.symbol					; Load instruction, if the character read is '.'.

	cmp		byte [ebp - 8], ','						; Compare the character read with ','.
	je		loadInstructions.symbol					; Load instruction, if the character read is ','.

	cmp		byte [ebp - 8], '['						; Compare the character read with '['.
	je		loadInstructions.leftBracket			; Load instruction, and increase the nesting level, if the character read is '['.

	cmp		byte [ebp - 8], ']'						; Compare the character read with ']'.
	je		loadInstructions.rightBracket			; Load instruction, and decrease the nesting level, if the character read is ']'.

	jmp 	loadInstructions.readingLoop			; Ignore the character that was read, if it's not a valid instruction.

.symbol:
	mov		al, byte [ebp - 8]						; Store the character read in al.
	mov		ecx, dword [ebp + 12]					; Store the current instruction's address in ecx.
	mov		byte [ecx], al							; Store the character read in the current instruction's address.

	inc		dword [ebp + 12]						; Increment the instruction count.
	jmp		loadInstructions.readingLoop			; Keep reading the file.

.leftBracket:
	inc		dword [ebp - 4]							; Increment the nesting level.
	jmp		loadInstructions.symbol					; Keep reading the file.

.rightBracket:
	dec		dword [ebp - 4]							; Decrement the nesting level.

	cmp		dword [ebp - 4], 0						; Compare the nesting level with 0.
	jl		loadInstructions.missingLeftBracket		; Exit the procedure with an error return value if the nesting level is negative (missing left bracket).

	jmp		loadInstructions.symbol					; Load instruction.

.checkNesting:
	cmp		dword [ebp - 4], 0						; Compare the nesting level with 0
	je		loadInstructions.success				; Exit the procedure with a success return value if if nesting level is 0 (all brackets have pairs).

	jmp		loadInstructions.missingRightBracket	; Exit the procedure with an error return value (missing right bracket).

.missingLeftBracket:
	mov		eax, MISSING_LEFT_BRACKET				; Set the error return value.
	jmp		loadInstructions.exit					; Exit the procedure.

.missingRightBracket:
	mov		eax, MISSING_RIGHT_BRACKET				; Set the error return value.
	jmp		loadInstructions.exit					; Exit the procedure.

.success:
	mov		eax, LOAD_SUCCESS						; Set the success return value.

.exit:
	mov		esp, ebp								; Clear stack.
	pop		ebp										; Restore caller's base pointer.
	ret												; Return to caller.




%endif