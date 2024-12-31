org 0x7e00
jmp main
nop

exit_status: db 0x0a, 0x0d,"program terminated with exit code ",0
loaded:db "loaded kernel interrupts", 0x0a, 0x0d
        db "spawned main thread", 0x0a, 0x0d, 0
last_sp: dw 0
last_instruction: dd 0 ;cs:ip
processes: db 0
memres: db 2 ;boot and kernel
SHELL: db "SHELL   "
startprogram:
    pop bx ;ip
    pop ax ;cs
    mov word[cs:last_instruction+2], ax;ip
    mov word[cs:last_instruction], bx;cs
    popf
    mov [cs:last_sp], sp
    mov ax, 790h
    mov ss, ax
    mov bp, 2ffh
    mov sp, bp
    mov dl, byte[cs:processes]
    xor dh, dh
    shl dl, 5
    mov bx, 800h
    add bx, dx
    mov es, bx
    mov ds, bx
    inc byte[cs:processes]
    pushf
    push bx
    push 0
    iret
    
endprogram:
    ;di=exit code
        pop ax
        pop ax
        pop ax ;collecting garbage
                push 0
                pop ds
                
                mov si, exit_status
                stc
                int 40h
                
                xchg di, ax
                mov ah, 0x0e
                int 10h
                
                mov sp,[ds:last_sp]
                
        pushf
        mov ax, [cs:last_instruction+2] ;cs
        mov es, ax
        mov ds, ax
        push ax
        mov ax, [cs:last_instruction] ;ip
        push ax
        dec byte[cs:processes]
        iret

load_file:
        
        mov cx, 51 ;up to 51 entries in 1 sector
        push bx
        mov bx, 0x7700
        .finder_loop:
                mov ax,[cs:bx]
                cmp word[ds:si],ax
                jne .next
                mov ax,[cs:bx+2]
                cmp word[ds:si+2],ax
                jne .next
                mov ax,[cs:bx +4]
                cmp word[ds:si+4],ax
                jne .next
                mov ax,[cs:bx+6]
                cmp word[ds:si+6],ax
                je .found
                .next:
                add bx,10 ;8+2=10
                loop .finder_loop
                jmp .not_found
        .found:
                mov ax, word [cs:bx + 8] ;lba
                pop bx
                mov cl, 1
                                mov dl, [cs:0x7c04]
                                cmp ax, 3
                                jb .error
                int 50h
                jc .not_found
                iret
        .not_found:
                mov al, "!"
                mov ah, 0x0e
                int 10h
                iret
                .error:
                xor ax, ax
                int 16h
                jmp far 0xf000:0xfff0
memsize:
        pushf
        ;ax=memory usage
        ;we need to scan stack too
        ;size is in sectors
        mov al, [cs:processes]
        shl al,1
        mov ah, [cs:memres]
        shl ah,1
        add al, ah
        ;al should contain the size of programs
        add al, 2+3
        popf
        iret

interrupts:
    xor ax, ax
    mov di, 30h * 4h ;calculated during compiling
    cli
    lea ax, [startprogram]
    mov [di], word ax
    mov ax, cs
    mov [di + 2], word ax


    xor ax, ax
    mov di, 31h * 4h ;calculated during compiling
    lea ax, [endprogram]
    mov [di], word ax
    mov ax, cs
    mov [di + 2], word ax

    mov di, 51h * 4h ;calculated during compiling
    lea ax, [load_file]
    mov [di], word ax
    mov ax, cs
    mov [di + 2], word ax

    mov di, 32h*4h
    mov ax, memsize
    mov [di], ax
    mov ax, cs
    mov [di+2], ax

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
    clc
    mov cx, 8
    int 40h
        
        mov si, SHELL
        
        mov bx, 800h
        mov es, bx
        xor bx, bx
        int 51h
        
    xor dx, dx
    int 30h
        
   


jmp main_thread
times 512-($-$$) db 0
