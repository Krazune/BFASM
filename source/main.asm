%include "system.asm"

global _start

segment .data
	helpMessage			db	'BFASM: Brainfuck interpreter for the IA-32 architecture.', 0xA, 'Usage: bfasm <path>', 0xA, 'Version: 2019.03.0', 0xA, 0
	helpMessageLength	equ	$ - helpMessage

segment .text
_start:
	cmp		dword [esp], 1			; Check if argument count is 1
	je		_start.singleArgument	; Print program information

	cmp		dword [esp], 2			; Check if argument count is 2
	je		_start.doubleArguments	; Call interpreter

	call	failureExit

.singleArgument:
	push	helpMessageLength
	push	helpMessage
	push	STDOUT
	call	sysWrite
	add		esp, 12

	call	successExit

.doubleArguments:
	; Call interpreter

	call	successExit

successExit:
	push	EXIT_SUCCESS
	call	sysExit

failureExit:
	push	EXIT_FAILURE
	call	sysExit