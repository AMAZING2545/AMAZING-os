org 0x7c00
use16
jmp main
nop

disk: db 0x00
;floppy disk
volume: db "amz os  "
sectors: dw 2880
heads: db 2
cylinders: db 80
sectors_per_track: db 16
filefat: db 1 ;(lba 1)
error: db ":( your pc ran into an error",0x0a, 0x0d
segmentation: db "stop 00h",0
starttext: db "starting AMAZINGos", 0x0a, 0x0d, "loading ivt", 0x0a, 0x0d,"done",0x0a, 0x0d, 0
diskopfailed:db "disk operation failed!",0
find: db "finding KERNEL16", 0x0a, 0x0d,0
found: db "found at ", 0x80,0x0a, 0x0d
kernel: db "starting kernel",0x0a, 0x0d,0

main:
    mov bp, 0x7bff
    mov sp,bp
    xor ax,ax
    mov es,ax
    mov ds,ax
    mov ss,ax

    call setint
    ;testing

    stc ; to zero
    lea si, [starttext] 
    int 40h

        lea si, [find]
        stc
        int 40h


    ;the fat is stored at 7700h
    xor di, di
    mov dl, [disk]
    mov cl, 1
    mov ax, 1
    mov bx, 0x7700
    int 50h
    xor di, di
    mov dl, [disk]
    mov cl, 1
    mov ax, 2
    mov bx, 0x7e00
    int 50h
        
    jmp 0x7e00


input:
    pusha
    ;global(interrupt 41h)
    ;unsigned short di = buffer
    ;unsigned short cx = stop
    ;bool carry = stop on enter
    jc .toenter
    .loop:
        xor ah, ah
        int 16h
        stosb
        mov ah, 0x0e ;printing while typing
        int 10h
        loop .loop
        jmp .end
    .toenter:
        ;enter: 0ah or 10d or 1100b
        xor ah, ah
        int 16h
        cmp al, 0x0d
        je .end
        cmp al, 0x0a
        je .end
                mov ah, 0x0e ;printing while typing
        int 10h
        cmp al, 8
        je .backspace
        stosb
        jmp .toenter
    .backspace:
        dec di                ; Adjust buffer pointer to remove the last character
        jmp .toenter          ; Continue looping
    .end:
        popa
        clc
        iret

print:
    pusha
    ;global(interrupt 40h)
    ;unsigned short si = base
    ;unsigned short cx = stop
    ;bool carry = print to zero
    mov ah, 0x0e
    jc .loopzero
    .loop:
        lodsb
        int 10h
        loop .loop
        jmp .end
    .loopzero:
        lodsb
        cmp al, 0
        je .end
        int 10h
        jmp .loopzero
    .end:
        popa
        clc
        iret
lba_to_chs:

    push ax
    push dx

    xor dx, dx                          ; dx = 0
    div word [sectors_per_track]        ; ax = LBA / SectorsPerTrack
                                        ; dx = LBA % SectorsPerTrack

    inc dx                              ; dx = (LBA % SectorsPerTrack + 1) = sector
    mov cx, dx                          ; cx = sector

    xor dx, dx                          ; dx = 0
    div word [heads]                ; ax = (LBA / SectorsPerTrack) / Heads = cylinder
                                        ; dx = (LBA / SectorsPerTrack) % Heads = head
    mov dh, dl                          ; dh = head
    mov ch, al                          ; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah                           ; put upper 2 bits of cylinder in CL

    pop ax
    mov dl, al                          ; restore DL
    pop ax
    ret


;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
;
diskread:
        push ds
        mov si, cs
        mov ds, si
    pusha
    push cx                             ; temporarily save CL (number of sectors to read)
    call lba_to_chs                     ; compute CHS

    pop ax                              ; AL = number of sectors to read
    mov ah, 02h
    test di, di
    jz .continue
    mov ah, 03h
.continue:

    int 13h
    jc .error
    mov al,"k"
    mov ah,0x0e
    int 10h
    popa 
        pop ds
    iret 

    .error:
        mov al, ah
        mov ah, 0x0e
        int 10h
        lea si, [diskopfailed]
        stc
        int 40h
        popa
                pop ds
        iret

setint:
    ;print (int 40h)
    xor ax, ax
    mov di, 40h * 4h ;calculated during compiling
    cli
    mov ax, print
    stosw
    mov ax, cs
    stosw


    ;input (int 41h)
    xor ax, ax
    mov di, 41h * 4h ;calculated during compiling

    mov ax, input
    stosw
    mov ax, cs
    stosw
        
        xor ax, ax
    mov di, 50h * 4h ;calculated during compiling

    mov ax, diskread
    stosw
    mov ax, cs
    stosw

    mov di, 36h * 4h ;calculated during compiling

    mov ax, 0x7f98
    stosw
    mov ax, cs
    stosw
    sti
    ret


times 510-($-$$) db 0
dw 0xaa55

