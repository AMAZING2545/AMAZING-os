org 8000h
jmp main
nop
default: db 0x0a, 0x0d,"C\>",0
invalid: db "invalid command",0x0a,0x0d,0
commands:db "list",0x0a, 0x0d,"load",0x0a, 0x0d, "regs",0x0a, 0x0d,"insp",0x0a, 0x0d, "exec",0x0a, 0x0d,"rebt",0x0a, 0x0d,"echo",0x0a, 0x0d0
keyboard: dq 0,0
ax_:db "ax:",0,0,"bx:"
bx_:db 0,0,"cx:"
cx_:db 0,0,"dx:"
dx_:db 0,0,"di:"
di_:db 0,0,"si:"
si_:db 0,0
main:
    mov si, default
    stc
    int 40h
    
    lea di,[keyboard]
    mov cx, 8
    xor ax, ax 
    rep stosw 
        
    mov di, keyboard
    stc
    int 41h

parse:
    mov si, keyboard
    cmp [si],dword "load"
    je lod
    cmp [si],dword "regs"
    je regs
    cmp [si],dword "list"
    je list
    cmp [si],dword "insp"
    je inspect
    cmp [si],dword "exec"
    je execute
    cmp [si],dword "help"
    je help
    cmp [si],dword "rebt"
    je reboot
    cmp [si],dword "echo"
    je echo
.invalid:
        mov si,invalid
        stc
        int 40h
        jmp main
        
list:
        mov si, 1000h
        mov cx, 512
        int 40h
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

lod:

        mov si, keyboard+5
        mov bx, 1242h
        mov dl, [7c04h]
	clc ;important
        int 51h
        jmp main

execute:
        
        xor cx, cx
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
	jmp far 0xf000:0xfff0
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

times 512-($-$$) db 0
