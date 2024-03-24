; mbr引导程序
; 加载setup程序到内存
; 跳转到setup程序

%include "config.asm"

[BITS 16]
section .mbr
	global _start
_start:
	org BOOT_ADDR
	; 将mbr引导程序复制到0x90000
	mov ax, BIOS_BOOT_SEG
	mov ds, ax
	mov ax, BOOT_SEG
	mov es, ax
	mov cx, MBR_SIZE
	xor si, si
	xor di, di
	rep movsb

	jmp BOOT_SEG:(new_start-BOOT_ADDR)

new_start:
	; 设置段寄存器 设置堆栈
	mov ax, BOOT_SEG
	mov ds, ax
	mov es, ax
	mov ax, STACK_SEG
	mov ss, ax
	mov sp, STACK_SIZE	; 堆栈0xF000
	xor bp, bp
	
	mov cx, boot_msg1
	mov bx, COLOR_BLUE
	call print_str

; 获取启动驱动器参数
	call get_drive_pram
; 加载setup程序到0x90200
load_setup:
	mov ax, BOOT_SEG
	mov es, ax
	mov bx, SETUP_OFFSET	; es:bx 0x80200
	mov cx, SETUP_SECTOR	; setup起始扇区
	mov dx, KERNEL_SECTOR - SETUP_SECTOR
	call read_drive
	test ah, ah
	jz load_setup_ok

load_setup_failed:
	jmp $

load_setup_ok:
	mov cx, boot_msg2
	mov bx, COLOR_GREEN
	call print_str
	mov ax, KERNEL_SIZE_KB
	call print_hex
; 加载kernel到0x11000
load_kernel:
	mov cx, boot_msg3
	mov bx, COLOR_BLUE
	call print_str

	mov ax, KERNEL_SEG
	mov es, ax
	mov bx, 0
	mov cx, KERNEL_SECTOR
	mov dx, KERNEL_SIZE
	call read_drive
	test ah, ah
	jz load_kernel_ok

load_kernel_failed:
	jmp $

load_kernel_ok:
	; 跳转到setup
	jmp BOOT_SEG:SETUP_OFFSET

; 获取启动驱动器参数
get_drive_pram:
	mov dl, BOOT_DRIVE
	xor ah, ah
	int 0x13	; 复位启动软驱

	mov ah, 0x8
	int 0x13
	mov byte [ds:drive_nr], dl
	inc dh
	mov byte [ds:drive_head_nr], dh	; 磁头数得到的是1，但是应该有两个磁头
	mov dx, cx
	and cx, 0x3F
	mov word [ds:drive_sector_nr], cx ; 每磁道扇区数
	mov cl, dh
	shr dl, 6
	mov ch, dl
	inc cx
	mov word [ds:drive_track_nr], cx ; 柱面数 得到的是0x4F 但应该是0x50
	ret

; 读取驱动器 cx读取扇区的编号 dx为读取扇区数量
; es:bx缓冲区 bx需要512对齐
read_drive:
	mov ax, cx
	inc ax
	push ax
	mov ax, dx
	dec ax
	push ax
	mov ax, bx
	add ax, 0x200
	jc add_es
	push ax
	mov ax, es
	push ax
	jmp _read_1
add_es:	; bx溢出 增加es
	push ax
	mov ax, es
	add ax, 0x1000
	push ax
_read_1:
	call read_1_sector
	test ah, ah
	jnz _read_1	; 读失败
	pop ax
	mov es, ax
	pop bx
	pop dx
	pop cx
	test dx, dx
	jnz read_drive
read_ok:
	mov ah, 0
	ret

; 读取1个扇区 cx读取扇区的编号 es:bx缓冲区
read_1_sector:
	push bx
	mov ax, cx
	xor dx, dx
	div word [ds:drive_sector_nr]
	push dx	; 扇区号
	xor dx, dx
	div word [ds:drive_head_nr]
	mov ch, al	; ax柱面号
	mov ax, dx	; dx磁头号
	shl dh, 6
	mov cl, dh
	pop dx
	inc dl
	and dl, 0x3F ; 扇区号
	or cl, dl
	mov bx, ax	; 磁头号
	mov al, 1	; 读一个扇区
	mov dh, bl	; 磁头号
	mov dl, BOOT_DRIVE
	pop bx
	mov ah, 0x02
	int 0x13
	ret

; 打印字符串功能
print_str:
	; print string at es:cx
	push cx
	mov si, cx
print_str_loop:
	mov cl, byte [es:si]
	test cl, cl
	jz print_str_end
	inc si
	jmp print_str_loop
print_str_end:
	mov ah, 0x03	; cursor position
	int 0x10
	pop ax
	mov bp, ax	; str
	mov cx, si
	sub cx, ax	; str length
	mov ax, 0x1301
	int 0x10
	ret
print_endl:
	; CR LR
	mov ax, 0x0E0D
	int 0x10
	mov al, 0x0A
	int 0x10
	ret

print_hex:
	; print hex number in ax
	mov bx, ax
	mov ax, 0x0E30
	int 0x10
	mov al, 0x78
	int 0x10
	mov cx, 4
print_hex_loop:
	mov al, bh
	shr al, 4
	and al, 0x0F
	add al, 0x37
	cmp al, 0x41	; >= A
	jg hex_a
	sub al, 7	; < A
hex_a:
	int 0x10
	shl bx, 4
	loop print_hex_loop
	mov al, 0x6b
	int 0x10
	mov al, 0x62
	int 0x10
	call print_endl
	ret

; data area

; 启动驱动器参数
boot_drive dw BOOT_DRIVE	; 启动设备驱动器号
drive_nr dw 0	; 驱动器数
drive_head_nr dw 0	; 驱动器磁头数
drive_sector_nr dw 0	; 每磁道扇区数
drive_track_nr dw 0	; 磁道数

; 启动提示字符串
boot_msg1:	db "Loading setup...", 0x0D, 0x0A, 0x00
boot_msg2: db "Kernel size:", 0
boot_msg3 db "Loading kernel...", 0x0D, 0x0A, 0x00

times (MBR_SIZE-2)-($-$$) db 0
dw MBR_MAGIC	; boot singature