#!/bin/bash
# Runs bfasm by storing the first program argument into a file, and passing it to bfasm.
# Used by the Dockerfile.

if [ $# -eq 0 ]
then
	bfasm
	exit 0
fi

# bfasm reads from files, so the input must be stored in a file first.
if [ $# -gt 0 ]
then
	echo $1 > program.bf
fi

# Execute bfasm with a custom sized tape.
bfasm program.bf $2