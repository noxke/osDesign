/**
 * task0
*/

.intel_syntax noprefix

.section .data
.global task2_img

/*========================================================================*/
# 任务1映射到地址
.align 0x1000
task2_img:
task_img_begin:
header_begin:
    .long 0x4B534154 # "TASK"
    .long header_end - header_begin
    .long task_begin - task_img_begin
    .long task_end - task_begin
    .long tss - task_img_begin
    .long tss_end - tss
    .long stack0 - task_img_begin
    .long stack0_top - stack0
    .long ldt - task_img_begin
    .long ldt_end - ldt
/*========================================================================*/
.align 8
tss:
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
    .long 0x00000000                # cr3
    .long task_entry - task_begin   # eip
    .long 0x200                 # eflags
    .long 0                     # eax
    .long 0                     # ecxx
    .long 0                     # edx
    .long 0                     # ebx
    .long stack_top - task_begin    # esp
    .long 0                     # ebp
    .long 0                     # esi
    .long 0                     # edi
    .word 0x1F                  # es
    .word 0
    .word 0x17                  # cs
    .word 0
    .word 0x27                  # ss
    .word 0
    .word 0x1F                  # ds
    .word 0
    .word 0x00                  # fs
    .word 0
    .word 0x00                  # gs
    .word 0
    .word 0x00                  # ldt
    .word 0
    .word 0
    .word io_map - tss          # iomap_base
io_map:
    .byte 0xFF
.align 4
tss_end:

# 内核态堆栈
stack0:
.fill 0x100, 1, 0
stack0_top:

.align 8
ldt:
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

ldt_end:
header_end:

/*========================================================================*/
task_begin:
# 任务代码
.align 4
task_entry:
    mov eax, 0xFF01
    mov ebx, 0x0500
    mov ecx, 0x074C     # L
    int 0x80
    mov eax, 0xFF01
    mov ebx, 0x0501
    mov ecx, 0x074F     # O
    int 0x80
    mov eax, 0xFF01
    mov ebx, 0x0502
    mov ecx, 0x0756     # V
    int 0x80
    mov eax, 0xFF01
    mov ebx, 0x0503
    mov ecx, 0x0745     # E
    int 0x80
    jmp task_entry
/*========================================================================*/
# 任务堆栈
.align 4
stack:
.fill 0x100, 4, 0
stack_top:
task_end:
/*========================================================================*/