%include "system.asm"
%include "loader.asm"
%include "interpreter.asm"




global _start




segment .rodata
	helpMessage			db	'BFASM: Brainfuck interpreter for the IA-32 architecture.', 0xA, 'Usage: bfasm <path> [tape size]', 0xA, 'Version: 2019.03.1', 0xA, 0
	helpMessageLength	equ	$ - helpMessage

	invalidArgumentCountMessage			db	'Invalid argument count.', 0xA, 'Usage: bfasm <path> [tape size]', 0xA, 0
	invalidArgumentCountMessageLength	equ	$ - invalidArgumentCountMessage

	invalidPathError		db	'Invalid path.', 0xA, 0
	invalidPathErrorLength	equ	$ - invalidPathError

	memoryError		db	'Memory error.', 0xA, 0
	memoryErrorLength	equ	$ - memoryError

	leftBracketError		db	'No matching left bracket.', 0xA, 0
	leftBracketErrorLength	equ	$ - leftBracketError

	rightBracketError		db	'No matching right bracket.', 0xA, 0
	rightBracketErrorLength	equ	$ - rightBracketError

	invalidTapeSizeError		db	'Invalid tape size.', 0xA, 0
	invalidTapeSizeErrorLength	equ	$ - invalidTapeSizeError




segment .data
	tapeSize	dd	30000




segment .bss
	instructionsAddress	resd	1
	instructionSize		resd	1




segment .text
_start:
	cmp		dword [esp], 1				; Check for single command line argument
	je		_start.singleArgument		; Print program information if single argument

	cmp		dword [esp], 2				; Check for double command line arguments
	je		_start.doubleArguments		; Call interpreter if double arguments

	cmp		dword [esp], 3				; Check for triple command line arguments
	je		_start.tripleArguments		; Call interpreter if triple arguments

	call	printArgumentCountError		; Print error if the argument count is greater than 2

	jmp		_start.failureExit			; Exit program with failure exit status on invalid argument count

.singleArgument:
	call	printInformation			; Print program information

	jmp		_start.successExit			; Exit program with success exit status

.doubleArguments:
	push	instructionSize				; Push instruction size's address
	push	instructionsAddress			; Push instructions address's address
	push	dword [esp + 16]			; Push second argument to be used as parameter to the interpreter
	call	load						; Load instructions
	add		esp, 12						; Clear stack arguments

	cmp		eax, LOAD_INVALID_PATH		; Check if path is invalid
	je		_start.invalidPath			; Exit program with failure exit status on invalid path

	cmp		eax, ZERO_INSTRUCTIONS		; Check if zero instructions
	je		_start.successExit			; Exit program with success exit status on zero instructions

	cmp		eax, MEMORY_ERROR			; Check if zero instructions
	je		_start.memoryError			; Exit program with failure exit status on memory error

	cmp		eax, MISSING_LEFT_BRACKET	; Check for missing left bracket return code
	je		_start.missingLeftBracket	; Print missing bracket error and exit program

	cmp		eax, MISSING_RIGHT_BRACKET	; Check for missing right bracket return code
	je		_start.missingRightBracket	; Print missing bracket error and exit program

	push	dword [tapeSize]			; Push tape size
	push	dword [instructionSize]		; Push instruction size
	push	dword [instructionsAddress]	; Push instructions address
	push	dword [esp + 16]			; Push second argument to be used as parameter to the interpreter
	call	interprete					; Call interpreter
	add		esp, 16						; Clear stack arguments

	cmp		eax, NO_ERROR				; Check for no error return code
	je		_start.successExit			; Exit program with success exit status

	cmp		eax, INVALID_PATH			; Check for invalid path return code
	je		_start.invalidPath			; Print invalid path error and exit program

	cmp		eax, TAPE_MEMORY_ERROR		; Check for memory error return code
	je		_start.memoryError			; Print memory error and exit program

.tripleArguments:
	push	dword [esp + 12]			; Push tape size string
	call	stoi						; Convert tape size string to integer
	add		esp, 4						; Clear stack arguments

	cmp		eax, -1						; Check if the string was converted successfully
	je		_start.invalidTapeSize		; Print invalid tape size error and exit program

	mov		dword [tapeSize], eax		; Store tape size in tape size global variable

	jmp		_start.doubleArguments		; Call interpreter with the rest of the arguments

.invalidPath:
	call	printInvalidPathError		; Print missing bracket error

	jmp		_start.failureExit			; Exit program with failure exit status

.invalidTapeSize:
	call	printInvalidTapeSizeError	; Print memory error

	jmp		_start.failureExit			; Exit program with failure exit status

.memoryError:
	call	printMemoryError			; Print memory error

	jmp		_start.failureExit			; Exit program with failure exit status

.missingLeftBracket:
	call	printLeftBracketError		; Print missing bracket error

	jmp		_start.failureExit			; Exit program with failure exit status

.missingRightBracket:
	call	printRightBracketError		; Print missing bracket error

	jmp		_start.failureExit			; Exit program with failure exit status

.successExit:
	push	EXIT_SUCCESS				; Set success exit status
	call	sysExit						; Exit program

.failureExit:
	push	EXIT_FAILURE				; Set failure exit status
	call	sysExit						; Exit program




printInformation:
	push	ebp					; Store base pointer
	mov		ebp, esp			; Set base pointer to stack pointer

	push	helpMessageLength
	push	helpMessage
	push	STDOUT
	call	sysWrite			; Print program information
	add		esp, 12				; Clear stack arguments

	mov		esp, ebp			; Clear stack
	pop		ebp					; Restore base pointer
	ret							; Return to caller




printArgumentCountError:
	push	ebp									; Store base pointer
	mov		ebp, esp							; Set base pointer to stack pointer

	push	invalidArgumentCountMessageLength
	push	invalidArgumentCountMessage
	push	STDERR
	call	sysWrite							; Print argument count error message
	add		esp, 12								; Clear stack arguments

	mov		esp, ebp							; Clear stack
	pop		ebp									; Restore base pointer
	ret											; Return to caller




printInvalidPathError:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	push	invalidPathErrorLength
	push	invalidPathError
	push	STDERR
	call	sysWrite				; Print invalid path error
	add		esp, 12					; Clear stack arguments

	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller




printMemoryError:
	push	ebp					; Store base pointer
	mov		ebp, esp			; Set base pointer to stack pointer

	push	memoryErrorLength
	push	memoryError
	push	STDERR
	call	sysWrite			; Print memory error
	add		esp, 12				; Clear stack arguments

	mov		esp, ebp			; Clear stack
	pop		ebp					; Restore base pointer
	ret							; Return to caller




printLeftBracketError:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	push	leftBracketErrorLength
	push	leftBracketError
	push	STDERR
	call	sysWrite				; Print missing left bracket error
	add		esp, 12					; Clear stack arguments

	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller




printRightBracketError:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	push	rightBracketErrorLength
	push	rightBracketError
	push	STDERR
	call	sysWrite				; Print missing left bracket error
	add		esp, 12					; Clear stack arguments

	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller




printInvalidTapeSizeError:
	push	ebp							; Store base pointer
	mov		ebp, esp					; Set base pointer to stack pointer

	push	invalidTapeSizeErrorLength
	push	invalidTapeSizeError
	push	STDERR
	call	sysWrite					; Print missing left bracket error
	add		esp, 12						; Clear stack arguments

	mov		esp, ebp					; Clear stack
	pop		ebp							; Restore base pointer
	ret									; Return to caller




stoi:
	push	ebp						; Store base pointer
	mov		ebp, esp				; Set base pointer to stack pointer

	mov		ecx, dword [ebp + 8]	; Load string address in register ecx
	cmp		byte [ecx], 0			; Check if first character is 0
	je		stoi.error				; Exit the procedure with a failure return value

	mov		eax, 0					; Set initial value to 0

.convertLoop:
	mov		ecx, dword [ebp + 8]	; Load current character address in register ecx
	movzx	ecx, byte [ecx]			; Store current character in register ecx

	cmp		ecx, 0					; Check if first character is 0
	je		stoi.exit				; Exit the procedure

	sub		ecx, '0'				; Convert character to digit

	cmp		ecx, 0					; Check if digit is below 0
	jl		stoi.error				; Exit the procedure with a failure return value

	cmp		ecx, 9					; Check if digit is above 9
	jg		stoi.error				; Exit the procedure with a failure return value

	mov		edx, 10					; Store 10 in register edx
	mul		edx						; Multiply current value by 10
	add		eax, ecx				; Add digit value to current value

	inc		dword [ebp + 8]			; Increment current character address

	jmp		stoi.convertLoop		; Keep converting the integer

.error:
	mov		eax, -1					; Set the failure return value

.exit:
	mov		esp, ebp				; Clear stack
	pop		ebp						; Restore base pointer
	ret								; Return to caller