org 7c00h


jmp start 

;fs header
spt: dw 512
heads: dw 512
tracks: dw 512


hello: db "starting system",0x0d, 0x0a, 0
load1: db 'loading SHELL   EXE',0x0d,0x0a,0

start:
    xor ax,ax
    mov ds,ax
    mov ss,ax
    ;the stack
    mov bp,0x7c00
    mov sp,bp
    xor ax, ax
    int 16
    mov ah, 0bh
    xor bx, bx
    mov bl, 1
    int 16
    mov di, hello
    call printzero 
    mov [current_lba],word 1
    mov cl, 1
    mov dl, 0x80
    mov bx, 7e00h
    call diskread
    mov di, load1
    call printzero
    jmp 0x7e0b


lbachs:

    push ax
    push dx

    xor dx,dx
    div word [spt]
    inc dx
    mov cx, dx
    xor dx, dx
    div word [heads]
    mov dh, dl
    mov ch, al
    shl ah, 6
    or cl, al

    pop dx
    pop ax
    ret
diskread:
    ;cl=sectors
    ;dl=drive number
    ;es:bs=address
    mov ax, [current_lba]
    push cx
    call lbachs
    pop ax
    mov ah, 2
    mov di, 3
    int 13h
    ;jc diskerror
    ret

printzero:
    mov ah, 0x0e
    .loop:
        mov al, [di]
        or al, al
        jz .end
        int 16
        inc di
        jmp .loop
    .end:
    xor di, di
    ret
print:
    mov ah, 0x0e
    .loop:
        mov al, [di]
        or al, al
        jz .end
        or si, si
        jz .end
        int 16
        inc di
        dec si
        jmp .loop
    .end:
    xor di, di
    ret

keyboard:
    xor ax, ax
    int 16h
    ;output in al
    ret

current_lba: dw 0
times 510-($-$$) db 0
dw 0xaa55

db 'SHELL   EXE'
jmp mainloop



mainloop:
    mov di, current_lba
    mov si, 2
    call print
    mov al, '>'
    mov ah, 0x0e
    int 10h
    .keyboard:
        call keyboard
        mov ah, 0x0e
        int 10h 
        jmp .keyboard
