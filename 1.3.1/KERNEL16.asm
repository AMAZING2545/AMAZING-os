org 0x7e00
jmp main
nop

exit_status: db 0x0a, 0x0d,"program terminated with exit code ",0
;2bytes sp, 4 bytes cs:ip(little endian)
last_sp: dw 7600h ;7606h ...
last_instruction: dw 7602h ;7608h ...
memres: db 2 ;boot and kernel
processes: db 0
malloc: dw 0
SHELL: db "config",0,0
startprogram:
    cmp al, 1
    je .malloc
    pop cx ;cs
    pop dx
    mov bx, [cs:last_sp]
    mov si, [cs:last_instruction]
    mov al, [cs:processes]
    .loop:
        test al, al
        jz .end
        add bx, 6
        add si, 6
        dec al
        jmp .loop
.end:

    mov word[cs:si+2], dx;ip
    mov word[cs:si], cx;cs
    popf
    mov [cs:last_sp], sp
    mov ax, 790h
    mov ss, ax
    mov bp, 2ffh
    mov sp, bp
    mov dx, word[cs:malloc]
    xor dh, dh
    shl dl, 5
    mov bx, 800h
    add bx, dx
    mov es, bx
    mov ds, bx
    inc byte[cs:processes]
    inc word[cs:malloc]
    pushf
    push bx
    push 0
    iret
.malloc:
    xor ax, ax
    mov al, [ds:0008h]
    add word[cs:malloc], ax
    iret

endprogram:
    ;di=exit code
        pop ax
        pop ax
        pop ax ;collecting garbage
        mov ax, [ds:0008h]
        inc ax
        sub word[cs:malloc], ax
        dec byte[cs:processes]
        push cs
        pop ds
                
        mov si, exit_status
        stc
        int 40h
                
        xchg di, ax
        mov ah, 0x0e
        int 10h


        mov si, [ds:last_instruction]
        mov bx, [ds:last_sp]
        mov al, [ds:processes]
        .loop:
             test al, al
             jz .end
             add bx, 6
             add si, 6
             dec al
             jmp .loop
.end:
        mov sp,[ds:bx]
                
        pushf
        mov ax, [cs:si+2] ;cs
        mov es, ax
        mov ds, ax
        push ax
        mov ax, [cs:si] ;ip
        push ax

        iret

load_file:
        
        mov cx, 46 ;up to 46 entries in 1 sector
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
                add bx,11 ;8+1+2=11
                loop .finder_loop
                jmp .not_found
        .found:
                mov ax, word [cs:bx + 8] ;lba
                mov cl,[cs:bx+10];sectors
                pop bx
                mov dl, [cs:0x7c04]
                xor di, di
                int 50h
                jc .not_found
                iret
        .not_found:
                mov al, "!"
                mov ah, 0x0e
                int 10h
                iret
memsize:
        ;ax=memory usage
        ;we need to scan stack too
        ;size is in half sectors
        mov al, [cs:processes]
        shl al,1
        mov ah, [cs:memres]
        shl ah,1
        add al, ah
        ;al should contain the size of programs
        add al, 2+3+1 ;2fs, 3 stack, 1 kernel heap
        iret

interrupts:
    mov di, 30h * 4h ;calculated during compiling
    cli
    mov ax, startprogram
    stosw
    mov ax, cs
    stosw


    mov di, 31h * 4h ;calculated during compiling
    mov ax, endprogram
    stosw
    mov ax, cs
    stosw

    mov di, 51h * 4h ;calculated during compiling
    mov ax, load_file
    stosw
    mov ax, cs
    stosw

    mov di, 32h*4h
    mov ax, memsize
    stosw
    mov ax, cs
    stosw

    sti


    ret
main:
    call interrupts

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
        mov di, bx
        int 51h
        
    xor dx, dx
    int 30h
        
   


jmp main_thread
times 512-($-$$) db 0