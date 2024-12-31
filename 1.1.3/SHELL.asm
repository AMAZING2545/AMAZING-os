org 0h
jmp main
nop

use16

default: db 0x0a, 0x0d,"C\>",0
invalid: db "invalid command",0x0a,0x0d,0
commands:db "list",0x0a, 0x0d, "regs",0x0a, 0x0d,"insp",0x0a, 0x0d, "exec",0x0a, 0x0d,"rebt",0x0a, 0x0d,"echo",0x0a, 0x0d,0
keyboard: dq 0,0
ax_:db "ax:",0,0,"bx:"
bx_:db 0,0,"cx:"
cx_:db 0,0,"dx:"
dx_:db 0,0,"di:"
di_:db 0,0,"si:"
si_:db 0,0
kb: db "kb used"
main:
        mov ax, cs
        mov ds, ax
    mov si, default
    stc
    int 40h
    
    mov di, keyboard
        mov cx, 8
        xor ax, ax 
        rep stosw 
        
    mov di, keyboard
    stc
    int 41h

parse:
    mov si, keyboard
    cmp [si],dword "regs"
    je regs
    cmp [si],dword "list"
    je list
    cmp [si],dword "insp"
    je inspect
    cmp [si],dword "exec"
    je execute
    cmp [si], dword "help"
    je help
    cmp [si],dword "rebt"
    je reboot
    cmp [si],dword "echo"
    je echo
    cmp [si],dword "exit"
    je exit
    cmp [si],dword "free"
    je free
.invalid:
        mov si,invalid
        stc
        int 40h
        jmp main
        
list:
        mov si, 7700h
                xor bx, bx
                push ds
                mov ds, bx
        mov cx, 512
        int 40h
                pop ds
        jmp main
        
help:
        mov si, commands
        stc
        int 40h
        jmp main
        
inspect:
        
        mov si, word[keyboard+5]
        mov cx, 512
        int 40h
        jmp main


execute:
        lea si, [keyboard+5]
        mov bx, 200h
                
        int 51h

        int 30h ;jump main after termination
        jmp main
        
regs:
        mov [ax_+2], ax
        mov [bx_], bx
        mov [cx_], cx
        mov [dx_], dx
        mov [di_], di
        mov [si_], si
        lea si, [ax_]
        mov cx, 30
        int 40h
                jmp main
reboot:
                jmp far 0xf000:0xfff0 ;the 8086 starts executing at this address
echo:
        mov ah, 0x0e
        mov al, 10
        int 16
        add al, 3
        int 16
        lea si, [keyboard+5]
        stc
        int 40h
        jmp main
exit:
        mov di, [ds: keyboard + 5]
        int 31h
free:
        int 32h ;memory free
        shr al, 2
        add al, '0'
        mov ah, 0x0e
        int 10h
        mov cx, 7
        mov si, kb
        clc
        int 40h
        jmp main
times 512-($-$$) db 0
