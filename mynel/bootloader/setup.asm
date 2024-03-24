; setup程序设置系统参数
; 获取系统参数 切换CPU实模式到保护模式
; 跳转到kernel

; 系统参数保存在0x90000 覆盖mbr
; 0x90000	; 扩展内存大小
; 0x90002	; 显存地址
; 0x90006	; 显存大小
; 0x90008	; 光标位置
; 0x9000A	; 显示器列数
; 0x9000B	; 显示器行数
; 0x9000C	; 显示页面
; 0x9000E	; 显示模式
; 0x9000F	; 字符列数
; 磁盘参数表
; 0x90100	; 驱动器数
; 0x90101	; 驱动器磁头数
; 0x90102	; 每磁道扇区数
; 0x90104	; 磁道数
;
; 0x90110 ; 后续磁盘扩展
; ...
;



%include "config.asm"

[BITS 16]
section .setup
    org BOOT_ADDR + SETUP_OFFSET
setup_entry:
	mov ax, BOOT_SEG
	mov ds, ax
	mov es, ax

    mov cx, setup_msg1
	mov bx, COLOR_BLUE
    call print_str

	; 清空mbr
	mov ax, BOOT_SEG
	mov ds, ax
	xor si, si
	mov cx, 0x200
clean_mbr:
	mov byte ds:[si], 0
	inc si
	loop clean_mbr

	; 获取内存大小
	mov cx, setup_msg2
	mov bx, COLOR_GREEN
	call print_str
	mov ah, 0x88	; get extended memory (kb)
	int 0x15
	mov word ds:[0], ax
	call print_hex

	; 获取光标位置
	mov ah, 0x03
	xor bh, bh
	int 0x10
	mov word ds:[8], dx

	; 获取显示模式
	mov ah, 0xf
	int 0x10
	mov word ds:[0xC], bx
	mov word ds:[0xE], ax

	; 显示器行列 预设80x25
	mov ax, 0x1950
	mov word ds:[0xA], ax
	; 显存预设 0xB8000 大小0x8000
	mov ax, 0x8000
	mov word ds:[2], ax
	mov word ds:[6], ax
	mov ax, 0xB
	mov word ds:[4], ax

	; 获取boot驱动器参数
	mov dl, BOOT_DRIVE
	xor ah, ah
	int 0x13	; 复位启动软驱
	mov ah, 0x8
	int 0x13
	mov byte ds:[100], dl
	inc dh
	mov byte ds:[101], dh	; 磁头数得到的是1，但是应该有两个磁头
	mov dx, cx
	and cx, 0x3F
	mov word ds:[102], cx ; 每磁道扇区数
	mov cl, dh
	shr dl, 6
	mov ch, dl
	inc cx
	mov word ds:[104], cx ; 柱面数 得到的是0x4F 但应该是0x50


	; 开始进入保护模式
	mov ax, BOOT_SEG
	mov es, ax
	mov cx, setup_msg3
	mov bx, COLOR_BLUE
	call print_str
	; 关中断
	cli

	; 加载段描述符表（临时gdt，idt表）
	mov ax, BOOT_SEG
	mov ds, ax
	lidt ds:[idt_48]	; 加载idt(空表)
	lgdt ds:[gdt_48] ; 加载gdt(临时)

enable_a20:
	; 开启A20地址线
	in al, 0x92
	or al, 0b00000010
	out 0x92, al
	; 检查A20地址线是否开启
	xor ax, ax
	mov ds, ax
	mov bl, byte ds:[0]
	mov al, 0x00
	mov byte ds:[0], al	; 将0x00存入0x0000:0x00地址(0地址)
	mov ax, 0xFFFF
	mov ds, ax
	mov al, 0xFF
	mov byte ds:[0x10], al	; 将0xFF存入0xFFFF:0x10地址(1M)
	xor ax, ax
	mov ds, ax
	mov al, byte ds:[0]	; 取出0地址的值测试
	mov byte ds:[0], bl
	test al, al
	jz a20_ok	; 开启A20成功
	jmp enable_a20	; 开启失败
a20_ok:

	call init_8259A

	; 开启保护模式
	mov eax, cr0
	or eax, 0x00000001
	mov cr0, eax

	mov eax, BOOT_ADDR	; 参数表地址
	jmp 0x18:0	; 跳转至内核


init_8259A:
; 初始化8259A
	mov	al, 0x11		; initialization sequence
	out	0x20, al		; send it to 8259A-1
	dw	0x00eb, 0x00eb		; jmp $+2, jmp $+2 	; $ 表示当前指令的地址，
	out	0xA0, al		; and to 8259A-2
	dw	0x00eb, 0x00eb
	mov	al, 0x20		; start of hardware int's (0x20)
	out	0x21, al
	dw	0x00eb, 0x00eb
	mov	al, 0x28		; start of hardware int's 2 (0x28)
	out	0xA1, al
	dw	0x00eb, 0x00eb
	mov	al, 0x04		; 8259-1 is master
	out	0x21, al
	dw	0x00eb, 0x00eb
	mov	al, 0x02		; 8259-2 is slave
	out	0xA1, al
	dw	0x00eb, 0x00eb
	mov	al, 0x01		; 8086 mode for both
	out	0x21,al
	dw	0x00eb, 0x00eb
	out	0xA1, al
	dw	0x00eb, 0x00eb
	mov	al, 0xFF		; 关闭所有中断
	out	0x21, al
	dw	0x00eb, 0x00eb
	out	0xA1, al
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

; 全局描述符表（临时，每个描述符项长8个字节）
gdt:
	dw	0,0,0,0	;第1个描述符，不使用BOOT_ADDR

	; 在GDT表的偏移量是0x08。内核代码段选择符。
	dw	0x3FFF		; limit=0x3FFF (0x4000*4K=64M)
	dw	0x0000		; base address=0
	dw	0x9A00		; code read/exec		; 代码段为只读，可执行
	dw	0x00C0		; granularity=4096, 386 ; 颗粒度4K，32位

	; 在GDT表的偏移量是0x10。内核数据段选择符。
	dw	0x3FFF		; limit=0x3FFF (0x4000*4K=64M)
	dw	0x0000		; base address=0
	dw	0x9200		; data read/write		; 数据段为可读可写
	dw	0x00C0		; granularity=4096, 386	; 颗粒度4K，32位

	; 在GDT表的偏移量是0x18。kernel加载数据段选择符。
	dw	(BOOT_ADDR-KERNEL_ADDR)/0x1000-1	; limit=0x7F (0x80*4K=512K)
	dw	(KERNEL_ADDR) & 0xFFFF				; base address=KERNEL_ADDR
	dw	0x9A00 | (KERNEL_ADDR >> 16)		; data read/exec
	dw	0x00C0		; granularity=4096, 386	; 颗粒度4K，32位


; 加载中断描述符表寄存器指令lidt要求的6字节操作数。
; 注：CPU要求在进入保护模式之前需设置idt表，因此这里先设置一个长度为0的空表。
idt_48:
	dw	0			; idt limit=0	; idt的限长
	dw	0, 0			; idt base=0L	; idt表在线性地址空间中的32位基地址

; 加载全局描述符表寄存器指令lgdt要求的6字节操作数。
gdt_48:
	dw	0x800		; gdt limit=2048, 256 GDT entries 表限长2k
	dw	gdt, BOOT_ADDR >> 16

setup_msg1 db "In setup...", 0x0D, 0x0A, 0x00
setup_msg2 db "Extended memory size:", 0
setup_msg3 db "Move to protected mode...", 0x0D, 0x0A, 0x00
