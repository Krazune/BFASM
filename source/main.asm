%include "system.asm"
%include "loader.asm"
%include "interpreter.asm"



global _start



segment .data
	helpMessage			db	'BFASM: Brainfuck interpreter for the IA-32 architecture.', 0xA, 'Usage: bfasm <path>', 0xA, 'Version: 2019.03.1', 0xA, 0
	helpMessageLength	equ	$ - helpMessage

	invalidArgumentCountMessage			db	'Invalid argument count.', 0xA, 'Usage: bfasm <path>', 0xA, 0
	invalidArgumentCountMessageLength	equ	$ - invalidArgumentCountMessage

	invalidPathError		db	'Invalid path.', 0xA, 0
	invalidPathErrorLength	equ	$ - invalidPathError

	memoryError		db	'Memory error.', 0xA, 0
	memoryErrorLength	equ	$ - memoryError

	leftBracketError		db	'No matching left bracket.', 0xA, 0
	leftBracketErrorLength	equ	$ - leftBracketError

	rightBracketError		db	'No matching right bracket.', 0xA, 0
	rightBracketErrorLength	equ	$ - rightBracketError



segment .bss
	instructionsAddress	resd	1
	instructionSize		resd	1



segment .text
_start:
	cmp		dword [esp], 1				; Check for single command line argument
	je		_start.singleArgument		; Print program information if single argument

	cmp		dword [esp], 2				; Check for double command line arguments
	je		_start.doubleArguments		; Call interpreter if double arguments

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

	push	dword [instructionSize]		; Push instruction size
	push	dword [instructionsAddress]	; Push instructions address
	push	dword [esp + 16]			; Push second argument to be used as parameter to the interpreter
	call	interprete					; Call interpreter

	cmp		eax, NO_ERROR				; Check for no error return code
	je		_start.successExit			; Exit program with success exit status

	cmp		eax, INVALID_PATH			; Check for invalid path return code
	je		_start.invalidPath			; Print invalid path error and exit program

.invalidPath:
	call	printInvalidPathError		; Print missing bracket error

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