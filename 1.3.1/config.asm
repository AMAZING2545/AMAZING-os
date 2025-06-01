jmp near main
nop
db "AMOS",0
file1:db "SHELL   "

main:
	lea si, [file2]
	mov bx, 200h;offset 512
	int 51h
    int 30h ;start process
    int 31h ;return to kernel
times 512-($-$$) db 0