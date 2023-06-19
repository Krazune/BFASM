FROM ubuntu:22.04 AS build

RUN apt update -y
RUN apt install -y nasm binutils

WORKDIR /tmp/bfasm-build/

COPY ./source/ .

RUN nasm -f elf main.asm
RUN ld -m elf_i386 -s -o bfasm main.o

FROM ubuntu:22.04

COPY --from=build /tmp/bfasm-build/bfasm/ /usr/local/bin/

WORKDIR /tmp/

COPY ./loader.sh /tmp

RUN chmod +x loader.sh

ENTRYPOINT ["./loader.sh"]