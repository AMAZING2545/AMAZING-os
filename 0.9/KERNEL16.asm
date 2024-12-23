org 0x7e00


jmp main
nop

exit_status: db 0x0a, 0x0d,"program terminated with exit code ",0

startprogram:
    pusha
    jc .system_prog
    mov ax, 124h ;this is after the fat + 64b for the stack
    mov ds, ax
    mov es, ax
    sub ax, 04h
    mov ss, ax
    mov bp, 64
    mov sp, bp
    popa
    jmp 0124h:0100h
    .system_prog:
        xor ax, ax
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov bp, 0x7bff ;system stack
        mov sp, bp
        popa
        jmp 8000h ;after the kernel
endprogram:
    ;di=exit code
    push ax
    xor ax,ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov bp, 0x7bff ;system stack
    mov sp, bp

    push di
    stc
    lea si,[exit_status]
    int 40h
    pop ax
    mov ah, 0x0e
    int 10h
    clc
    jmp main_thread

interrupts:
    xor ax, ax
    mov di, 30h * 4h ;calculated during compiling
    cli
    mov ax, startprogram
    stosw
    mov ax, cs
    stosw
    sti

    xor ax, ax
    mov di, 31h * 4h ;calculated during compiling
    cli
    mov ax, endprogram
    stosw
    mov ax, cs
    stosw
    sti

    ret
main:
    call interrupts
    jmp main_thread
main_thread:
    xor ax, ax
    int 16h
    mov dl, 0x00
    mov cl, 1
    mov ax, 1
    mov bx, 0xf000
    int 50h

    mov ax, word [0xf01a]
    mov dl, 0x00
    mov cl, 1
    mov di, 124h
    mov es, di
    mov bx, 0x100
    int 50h

    mov ax, 0
    mov es, ax

    int 30h


jmp main_thread
times 512-($-$$) db 0

org 100h
jmp a
nop
string: db 0x0a, 0x0d,"hello weirdo",0x0a, 0x0d, 0
a:
    stc
    lea si,[string]
    int 40h
    mov di,"he"
    int 31h
times 512-($-$$) db 0
