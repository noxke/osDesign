/*
boot程序
32位保护模式
*/

.intel_syntax noprefix

.global idt, gdt
.global stack0, stack0_top, tss0, ldt0, move_task0
.extern current_task

# .org 0x00000
# 页目录位于0地址
pg_dir      = 0x00000
# 16个 页表
pg0         = 0x01000
pg15        = 0x10000


# .org 0x11000
.section .boot, "awx"
.extern main
.global _start


# idt表
idt:
    # 此处为idt, 完成跳转后被覆盖
    jmp _start

.align 0x800
# gdt表
gdt:
    .quad 0x0000000000000000    # 第一项空表
    .quad 0x00C09A0000003FFF    # 内核代码段 base=0 limt=64M
    .quad 0x00C0920000003FFF    # 内核数据段 base=0 limt=64M
    .quad 0x00C0920000003FFF    # 内核堆栈段 base=0 limt=64M
    .fill 252, 8, 0             # 用于任务的tss, ldt


.align 0x1000
_start:
    # 设置段寄存器
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    xor ax, ax
    mov gs, ax  # gs fs不使用
    mov fs, ax
    mov esp, 0x90000    # 设置临时内核堆栈 0x80000-0x90000(64kb)

    call setup_idt  # 设置中断描述符表
    call setup_gdt  # 设置段描述符表
_new_cs:
    mov ax, 0x18
    mov ss, ax
    mov esp, 0x90000   # 栈顶0x90000
    call setup_page # 设置分页
    # 调用内核主函数
    push 0
    push 0
    push 0
    call main
    jmp $


# 默认idt中为未定义中断
unknow_int:
    iret

setup_idt:
    lea eax, unknow_int
    mov edx, 0x00080000 # 选择子0x0008 内核代码段
    mov dx, ax          # 入口低16位
    mov ax, 0x8E00      # 中断门
    lea edi, idt
    mov ecx, 0x100      # 256项
loop_setidt:
    mov [edi], edx
    mov [edi+4], eax
    add edi, 8
    loop loop_setidt
    lidt idt_descr
    ret

setup_gdt:
    lgdt gdt_descr
    add esp, 4
    jmp 0x08:_new_cs

setup_page:
    mov ecx, 1024*17   # 16个页表+页目录
    xor eax, eax
    xor edi, edi
    cld
    rep stosd

    # 初始化页目录前16项
    mov edi, 15*4
    mov eax, 0x00010007 # set present bit/user r/w
    std
_next_pg_dir:
    stosd
    sub eax, 0x1000
    cmp eax, 0x1000
    jae _next_pg_dir

    # 初始化页表
    mov edi, pg15+0xFFC
    mov eax, 0x03FFF007
    std
_next_pg:
    stosd
    sub eax, 0x1000
    jae _next_pg

    # 设置页目录表基地址寄存器cr3（保存页目录表的物理地址）
    xor eax, eax
    mov cr3, eax    # 设置页目录寄存器 页目录基址0
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax    # 修改cr0 PG 开启分页
    ret

# 两字节限长 4字节基址
.align 4
idt_descr:
    .word 256 * 8 - 1 # 256项
    .long idt

.align 4
gdt_descr:
    .word 256 * 8 - 1 # 256项
    .long gdt
/*========================================================================*/
.section .text
move_task0:
    mov ax, 0x20
    ltr ax    # tss0
    mov ax, 0x2B
    lldt ax   # ldt0

    mov eax, esp
    push 0x27   # ss
    push eax    # esp
    pushfd
    pop eax
    or eax, 0x200
    push eax    # eflags
    push 0x17   # cs
    lea eax, _task0_entry
    push eax    ## rip
    mov ax, 0x1F
    mov es, ax
    mov ds, ax
    xor ax, ax
    mov fs, ax
    mov gs, ax

    iret    # 使用iret切换到task0
_task0_entry:
    xor eax, eax
    mov [current_task], eax # 设置当前任务为0号任务
    ret
// task0的tss与ldt
.align 8
tss0:
    .word 0
    .word 0
    .long stack0_top - stack0   # esp0
    .word 0x0C                  # ss0
    .word 0
    .long 0
    .word 0
    .word 0
    .long 0
    .word 0
    .word 0
    .long 0                     # cr3
    .long 0                     # eip
    .long 0                     # eflags
    .long 0                     # eax
    .long 0                     # ecxx
    .long 0                     # edx
    .long 0                     # ebx
    .long 0                     # esp
    .long 0                     # ebp
    .long 0                     # esi
    .long 0                     # edi
    .word 0                     # es
    .word 0
    .word 0                     # cs
    .word 0
    .word 0                     # ss
    .word 0
    .word 0                     # ds
    .word 0
    .word 0                     # fs
    .word 0
    .word 0                     # gs
    .word 0
    .word 0x2B                  # ldt
    .word 0
    .word 0
    .word io_map - tss0          # iomap_base
io_map:
    .byte 0xFF
.align 4
tss_end:

# 内核态堆栈
stack0:
.fill 0x100, 1, 0
stack0_top:

.align 8
ldt0:
# ldt_none         0x04
    .quad 0x0000000000000000

# ldt_ss0          0x0C
    .quad 0x0000000000000000

# ldt_code         0x17
    .quad 0x0000000000000000

# ldt_data         0x1F
    .quad 0x0000000000000000

# ldt_stack        0x27
    .quad 0x0000000000000000
/*========================================================================*/