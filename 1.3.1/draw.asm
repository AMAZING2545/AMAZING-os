use16
include "amazingos.asm"
draw_loop:
	call keyboard
	mov ah, 0x0c
	mov al, 15
	int 10h	
	push dx
	push cx
	dec bx
	jnz draw_loop
draw_loop1:
	call keyboard
	mov ah, 0x0c
	mov al, 15
	int 10h	
	push dx
	push cx
	mov si, sp
	mov dx,[ss:si+6]
	mov cx,[ss:si+4]
	mov ah, 0x0c
	mov al, 2
	int 10h	
	pop cx
	pop dx
	jmp draw_loop1
keyboard:
	mov ah, 1
	int 16h
	jz keyboard
	xor ah, ah
	int 16h
	cmp ah, 11h
	je .down
	cmp ah , 1eh
	je .left
	cmp ah , 1fh
	je .up
	cmp ah , 20h
	je .right
	cmp ah, 1
	je exit
	.end:
	jmp keyboard
.up:
	inc dx
	ret
.down:
	dec dx
	ret
.right:
	inc cx
	ret
.left:
	dec cx
	ret
main:
	mov ah, 0
	mov al, 0x04
	int 10h
	mov bx, 5
	call draw_loop
exit:
	mov ah, 0
	mov al, 2
	int 10h
	mov di, '0'
	int 31h