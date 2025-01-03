org 0
main:
        INT 12H
        mov di, BUFFER+4
        call decimal
        mov si, MSG0
        stc
        int 40h
        mov si, BUFFER+2
        mov cx, 3
        int 40h
        mov si, msg1
        mov cx, 5
        int 40h

        int 12h
        push ax
        int 32h
        shr al, 2
        xor ah, ah
        pop dx
        sub dx, ax
        mov ax, dx

        mov di, BUFFER+4
        call decimal
        mov si, BUFFER+2
        mov cx, 3
        int 40h
        mov si, msg2
        stc
        int 40h
        MOV DI, '0'
        INT 31h
decimal:
        MOV BX, 10
        MOV CL, 5
        .LOOP:
            DEC CL
            XOR DX, DX
            DIV BX
            PUSH AX
            ADD DL ,'0'
            MOV [DI], DL
            DEC DI
            POP AX
            TEST CL, CL
            JNZ .LOOP
            ret




MSG0: DB 0x0a,0x0d,"fetch 1.0",0x0a, 0x0d, 0
msg1: db "kb total",0x0a, 0x0d, 0
msg2: db "kb free", 0x0a, 0x0d, 0

BUFFER: DB 0,0,0,0,0
