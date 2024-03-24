/**
 * 中断函数
*/

.intel_syntax noprefix

.section .text
.global system_call, timer_interrupt
.extern p_dsp_info, do_timer, do_schedule


/**
 * draw_at(posi, char)
 * bx 为显示位置 cx为显示字符
 * 在指定位置处显示字符
*/
__SYS_draw     = 0xFF01
__SYS_sche     = 0xFF02

draw_at:
    mov ax, 0x10
    mov ds, ax
    mov es, ax

    xor eax, eax
    mov esi, [p_dsp_info]
    mov dl, [esi+8]              # 显示器列数
    mov al, bh
    mul dl
    mov edx, eax                # 计算行位置
    xor eax, eax
    mov al, bl
    add edx, eax                # 计算列位置
    shl edx, 1
    add edx, [esi+0]            # 显存地址
    mov [edx], cx
    xor eax, eax
    jmp ret_from_syscall

sched:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    call do_schedule
    jmp ret_from_syscall

/**
 * syscall参数使用寄存器传递
 * eax系统调用号
 * ebx   ecx   edx   esi   edi
 * eax返回值
*/
system_call:
    push ebp
    mov ebp, esp
    push ds
    push es
    push eax
    push edx
    push ecx
    push ebx
    push esi
    push edi

    cmp eax, __SYS_draw
    jz draw_at
    cmp eax, __SYS_sche
    jz sched

ret_from_syscall:
    pop edi
    pop esi
    pop ebx
    pop ecx
    pop edx
    pop eax
    pop es
    pop ds
    pop ebp
    iret

timer_interrupt:
    push ebp
    mov ebp, esp
    push ds
    push es
    push eax
    push edx
    push ecx
    push ebx
    push esi
    push edi

    mov	al, 0x20
	out	0x20, al # 发送 EOI

    mov ax, 0x10
    mov ds, ax
    mov es, ax

    call do_timer
    call do_schedule
_timer_end:
    jmp ret_from_syscall    # 中断返回 任务切换

