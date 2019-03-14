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
	cmp		dword [esp], 1			; Check if argument count is 1
	je		_start.singleArgument	; Print program information

	cmp		dword [esp], 2			; Check if argument count is 2
	je		_start.doubleArguments	; Call interpreter

	push	invalidArgumentCountMessageLength
	push	invalidArgumentCountMessage
	push	STDERR
	call	sysWrite							; Print invalid argument count error message
	add		esp, 12

	call	failureExit

.singleArgument:
	push	helpMessageLength
	push	helpMessage
	push	STDOUT
	call	sysWrite
	add		esp, 12

	call	successExit

.doubleArguments:
	push	dword [esp + 8]	; Push input file path (second program argument)
	call	interprete		; interprete input file

	push	eax				; Use interpreter's return code as program exit status
	call	sysExit



successExit:
	push	EXIT_SUCCESS
	call	sysExit



failureExit:
	push	EXIT_FAILURE
	call	sysExit