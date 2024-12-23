org 0x7e00
jmp main
nop

exit_status: db 0x0a, 0x0d,"program terminated with exit code ",0
loaded:db "loaded kernel interrupts", 0x0a, 0x0d
        db "spawned main thread", 0x0a, 0x0d, 0
last_sp: dw 0,0,0,0
last_instruction: dd 0,0,0,0;up to 4 processes
processes: db 0
SHELL: db "SHELL   "

startprogram:
    pop bx ;cs
        pop ax ;ip
        lea di,[last_instruction]
        lea si, [last_sp]
        mov dl, [processes]
        .loop1:
                cmp dl, 0
                je .skip1
                add di, 4
                add si, 2
                dec dl
                jmp .loop1
                
        .skip1:
        
    mov word[di+2], ax;ip
        mov word[di], bx;cs
        add sp, 2
    mov [si], sp
        
        xor ch,ch
    mov ax, 124h ;this is after the fat + 64b for the stack
        mov cl,[processes]
        cmp cl,0
        je .skip
        .loop:
                add ax, 36
                loop .loop
        .skip:
        inc byte[processes]
        
    mov ds, ax
    mov es, ax
    sub ax, 04h
    mov ss, ax
    mov bp, 64
    mov sp, bp
        add ax, 4
        push ax
        push 2
        iret ;tricking the system that i returned from a call
    
endprogram:
    ;di=exit code
        ;dh=jump to system
        pop ax
        pop ax
        pop ax ;collecting garbage
        push 0
        pop ds
        mov bx, di
        dec byte[processes]
    mov cl,[processes]
        mov ax, 124h
        mov si, last_sp
        mov di, last_instruction
        
        xor ch,ch
        cmp cl, 0
        je .skip
        .loop:
                add ax, 36
                add si, 2
                add di, 4
                loop .loop
        .skip:
        
        cmp dh, 1
        jge .system
        
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov bp, 64
    mov sp, word [si]
        jmp .skip1
        .system:
        
        xor ax, ax
        mov ds, ax
    mov es, ax
    mov ss, ax
        mov bp, 7bffh
        mov sp, word [si]
        .skip1:
    stc
    lea si,[exit_status]
    int 40h
    mov ax, bx
    mov ah, 0x0e
    int 10h
        pushf
    push word[di+2]
        push word[di]
        iret

load_file:
        mov cx, 51 ;up to 51 entries in 1 sector
        push dx
        push bx
        mov bx, 0x1000
        .finder_loop:
                mov ax,[bx]
                cmp word[si],ax
                jne .next
                mov ax,[bx+2]
                cmp word[si+2],ax
                jne .next
                mov ax,[bx +4]
                cmp word[si+4],ax
                jne .next
                mov ax,[bx+6]
                cmp word[si+6],ax
                je .found
                .next:
                add bx,10 ;8+2=10
                loop .finder_loop
                jmp .not_found
        .found:
                mov ax, word [bx + 8] ;lba
                pop bx
                pop dx
                mov cl, 1
                int 50h
                jc .not_found
                iret
        .not_found:
                mov al, "!"
                mov ah, 0x0e
                int 10h
                iret
interrupts:
    xor ax, ax
    mov di, 30h * 4h ;calculated during compiling
    cli
    lea ax, [startprogram]
    mov [di], word ax
    mov ax, 00
    mov [di + 2], word ax


    xor ax, ax
    mov di, 31h * 4h ;calculated during compiling
    lea ax, [endprogram]
    mov [di], word ax
    mov ax, 00
    mov [di + 2], word ax

    mov di, 51h * 4h ;calculated during compiling
    lea ax, [load_file]
    mov [di], word ax
    mov ax, 00
    mov [di + 2], word ax
    sti

    ret
main:
    call interrupts
        lea si, [loaded]
        stc
        int 40h
    jmp main_thread
main_thread:
    xor ax, ax
    int 16h

    mov si, SHELL
    mov bx, 0x8000
    mov dl, [0x7c04]
    int 51h
    mov si, SHELL
    clc
    mov cx, 8
    int 40h

    jmp 8000h ;not using int 30h 


jmp main_thread
times 512-($-$$) db 0

