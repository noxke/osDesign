/*
 * 任务创建
*/

#include <stdint.h>
#include <task.h>
#include <tty.h>
#include <system.h>
#include <asm.h>

int current_task;
uint64_t clock_ticks = 0;

struct task_struct tasks[TASK_NR];

void set_tss_desc(int pid, uint32_t addr)
{
    uint16_t *tss = (uint16_t *)(&gdt + 4 + pid * 2);
    *(tss+0) = sizeof(struct tss_struct);
    *(tss+1) = addr & 0xFFFF;
    *(tss+2) = ((addr >> 16) & 0xFF) | (0x89 << 8);
    *(tss+3) = (addr >> 16) & 0xFF00;
}

void set_ldt_desc(int pid, uint32_t addr)
{
    uint16_t *ldt = (uint16_t *)(&gdt + 5 + pid * 2);
    *(ldt+0) = 40;  // ldt共有5项
    *(ldt+1) = addr & 0xFFFF;
    *(ldt+2) = ((addr >> 16) & 0xFF) | (0x82<<8);
    *(ldt+3) = (addr >> 16) & 0xFF00;
}

#define SEG_TYPE_SS0    0x4092
#define SEG_TYPE_CODE   0xC0FA
#define SEG_TYPE_DATA   0xC0F2

#define SET_SEG(seg, addr, limt, type) \
*((uint16_t *)(seg)+0) = (limt) & 0xFFFF; \
*((uint16_t *)(seg)+1) = (addr) & 0xFFFF; \
*((uint8_t *)(seg)+4) = ((addr)>>16) & 0xFF; \
*((uint8_t *)(seg)+5) = (type) & 0xFF; \
*((uint8_t *)(seg)+6) = (((limt)>>16) & 0x0F) | ((type) >> 8); \
*((uint8_t *)(seg)+7) = ((addr)>>24) & 0xFF;

#define va_pg(pg_dir, va) \
((((uint32_t *)(pg_dir))[(uint32_t)(va)>>22] & 0xFFFFF000) + \
(((uint32_t)(va) >> 10) & 0xFFC))

#define set_va_pg(pg_dir, va, fram) \
*(uint32_t *)va_pg((pg_dir), (va)) = (fram);

void init_task()
{
    current_task = 0xFFFFFFFF;
    // 初始化任务 初始化任务0
    for (int i = 0; i < TASK_NR; i++)
    {
        tasks[i].pid = i;
        tasks[i].status = STATUS_NULL;
    }
    // 设置ldt0
    SET_SEG(&ldt0+1, (uint32_t)&stack0, \
    (uint32_t)&stack0_top-(uint32_t)&stack0-1, SEG_TYPE_SS0);
    SET_SEG(&ldt0+2, 0, (mem_size >> 12) - 1, SEG_TYPE_CODE);
    SET_SEG(&ldt0+3, 0, (mem_size >> 12) - 1, SEG_TYPE_DATA);
    SET_SEG(&ldt0+4, 0, (mem_size >> 12) - 1, SEG_TYPE_DATA);
    // 设置gdt中的tss ldt描述符
    set_tss_desc(0, (uint32_t)&tss0);
    set_ldt_desc(0, (uint32_t)&ldt0);
    tasks[0].task_base = 0;
    tasks[0].priority = 1;
    tasks[0].counter = 1;
    tasks[0].status = STATUS_RUN;
}

void new_task(struct task_img *img, uint32_t priority)
{
    uint32_t pid = TASK_NR;
    for (int i = 0; i < TASK_NR; i++)
    {
        if (tasks[i].status == STATUS_NULL)
        {
            pid = i;
            tasks[i].status = STATUS_WAIT;
            break;
        }
    }
    if (pid == TASK_NR)
    {
        // 任务已满
        return;
    }
    // 为任务头分配页面
    struct task_img *task_base = (struct task_img *)kmalloc_page();
    if (task_base == NULL)
    {
        tasks[pid].status = STATUS_NULL;
        return;
    }
    // 复制任务头到新页面
    kmemcpy((void *)task_base, (void *)img, img->header_size);
    // 分配页面并加载任务
    for (uint32_t i = 0; i < img->task_size; i += 0x1000)
    {
        uint32_t pg = (uint32_t)kmalloc_page();
        if (pg == NULL)
        {
            // 分配失败 回收以前分配失败的所有页面
            kfree_page((void *)task_base);
            tasks[pid].status = STATUS_NULL;
            return;
        }
        uint32_t cpy_size = img->task_size - i;
        if (cpy_size > 0x1000) cpy_size = 0x1000;
        kmemcpy((void *)pg, (void *)((uint32_t)img + img->task_off + i), cpy_size);
    }
    // 设置ldt
    uint32_t header_base = (uint32_t)task_base;
    uint32_t text_base = (uint32_t)task_base + 0x1000;
    uint64_t *ldt = (uint64_t *)(task_base->ldt_off + (uint32_t)task_base);
    // 第一项为null
    *(ldt+0) = 0;
    // ring0堆栈段
    uint8_t *ldt_ss0 = (uint8_t *)(ldt+1);
    SET_SEG(ldt_ss0, header_base+task_base->stack0_off, \
    task_base->stack0_size - 1, SEG_TYPE_SS0);
    // code代码段
    uint8_t *ldt_code = (uint8_t *)(ldt+2);
    SET_SEG(ldt_code, text_base, \
    (task_base->task_size >> 12) - 1, SEG_TYPE_CODE);
    // data数据段
    uint8_t *ldt_data = (uint8_t *)(ldt+3);
    SET_SEG(ldt_data, text_base, \
    (task_base->task_size >> 12) - 1, SEG_TYPE_DATA);
    // stack堆栈段
    uint8_t *ldt_stack = (uint8_t *)(ldt+4);
    SET_SEG(ldt_stack, text_base, \
    (task_base->task_size >> 12) - 1, SEG_TYPE_DATA);

    // 设置tss
    struct tss_struct *tss = (struct tss_struct *)(task_base->tss_off + (uint32_t)task_base);
    tss->cr3 = 0;
    tss->ldt = ((5 + pid * 2) << 3) | 0b011;    // RPL3
    // 设置gdt中的tss ldt描述符
    set_tss_desc(pid, (uint32_t)tss);
    set_ldt_desc(pid, (uint32_t)ldt);
    // 任务准备完成 设置状态可运行
    tasks[pid].task_base = (uint32_t)task_base;
    tasks[pid].priority = priority;
    tasks[pid].counter = priority;
    tasks[pid].status = STATUS_RUN;
}

char clock_s[32] = {"CLOCK_TICKS: 0x"};
void do_timer()
{
    clock_ticks++;
    for (int i = 0; i < 16; i++)
    {
        char ch;
        ch = clock_ticks >> (60 - 4 * i) & 0xF;
        ch += (ch >= 10) ? 55 : 48;
        clock_s[i+15] = ch;
    }
    draw_str(0x0300, COLOR_WHITE, clock_s);
}

void do_schedule()
{
    int pid = -1;
    int max_counter = 0;
    if (current_task < 0)
    {
        return;
    }
    // 检查当前任务时间片是否用完
    if (tasks[current_task].counter > 0)
    {
        tasks[current_task].counter--;
        return;
    }
    // 寻找剩余时间片最大的任务
    for (int i = 0; i < TASK_NR; i++)
    {
        if (tasks[i].status != STATUS_RUN)
        {
            continue;
        }
        if (tasks[i].counter > max_counter)
        {
            max_counter = tasks[i].counter;
            pid = i;
        }
    }
    // 如果pid依然小于0 表示所有任务时间片都为0
    // 使用priority重置时间片并找到时间片最大的任务
    if (pid < 0)
    {
        tasks[0].counter = tasks[0].priority;
        max_counter = tasks[0].counter;
        pid = 0;
        for (int i = 1; i < TASK_NR; i++)
        {
            if (tasks[i].status != STATUS_RUN)
            {
                continue;
            }
            tasks[i].counter = tasks[i].priority * CLOCK_CYCLE;
            if (tasks[i].counter > max_counter)
            {
                max_counter = tasks[i].counter;
                pid = i;
            }
        }
    }
    if (pid >= 0 && pid != current_task)
    {
        current_task = pid;
        tasks[current_task].counter--;
        switch_to(pid);
    }
    return;
}