%include "system.asm"
%include "interpreter.asm"



global _start



segment .data
	helpMessage			db	'BFASM: Brainfuck interpreter for the IA-32 architecture.', 0xA, 'Usage: bfasm <path>', 0xA, 'Version: 2019.03.0', 0xA, 0
	helpMessageLength	equ	$ - helpMessage

	invalidArgumentCountMessage			db	'Invalid argument count.', 0xA, 'Usage: bfasm <path>', 0xA, 0
	invalidArgumentCountMessageLength	equ	$ - invalidArgumentCountMessage



segment .text
_start:
	cmp		dword [esp], 1			; Check for single command line argument
	je		_start.singleArgument	; Print program information if single argument

	cmp		dword [esp], 2			; Check for double command line arguments
	je		_start.doubleArguments	; Call interpreter if double arguments

	call	printArgumentCountError	; Print error if the argument count is greater than 2

	jmp		_start.failureExit		; Exit program with failure exit status on invalid argument count

.singleArgument:
	call	printInformation		; Print program information

	jmp		_start.successExit		; Exit program with success exit status

.doubleArguments:
	push	dword [esp + 8]			; Push second argument to be used as parameter to the interpreter
	call	interprete				; Call interpreter

	push	eax						; Push interpreter's return value to be used as the program exit status
	call	sysExit					; Exit program

.successExit:
	push	EXIT_SUCCESS			; Set success exit status
	call	sysExit					; Exit program

.failureExit:
	push	EXIT_FAILURE			; Set failure exit status
	call	sysExit					; Exit program



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