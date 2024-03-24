#include <stdint.h>

// 最大支持126个任务
#define TASK_NR 126
// 任务内存空间从1M开始
#define TASK_BASE 0x100000

#define STATUS_NULL 0
#define STATUS_WAIT 1
#define STATUS_RUN  2

#define TASK_MAGIC 0x4B534154

// 时钟周期50
#define CLOCK_CYCLE 50

struct tss_struct
{
    uint16_t back_link;
    uint16_t _0;
    uint32_t esp0;
    uint16_t ss0;
    uint16_t _1;
    uint32_t esp1;
    uint16_t ss1;
    uint16_t _2;
    uint32_t esp2;
    uint16_t ss2;
    uint16_t _3;
    uint32_t cr3;
    uint32_t eip;
    uint32_t eflags;
    uint32_t eax;
    uint32_t ecx;
    uint32_t edx;
    uint32_t ebx;
    uint32_t esp;
    uint32_t ebp;
    uint32_t esi;
    uint32_t edi;
    uint16_t es;
    uint16_t _4;
    uint16_t cs;
    uint16_t _5;
    uint16_t ss;
    uint16_t _6;
    uint16_t ds;
    uint16_t _7;
    uint16_t fs;
    uint16_t _8;
    uint16_t gs;
    uint16_t _9;
    uint16_t ldt;
    uint16_t _10;
    uint16_t _11;
    uint16_t iomap_base;
};

// 任务的开头存储与任务相关的信息
struct task_img
{
    uint32_t magic_number;
    uint32_t header_size;  // 任务头大小 小于4kb
    uint32_t task_off;  // 任务数据代码段偏移 
    uint32_t task_size; // 任务段大小
    uint32_t tss_off;
    uint32_t tss_size;
    uint32_t stack0_off;    // ring0栈
    uint32_t stack0_size;   // ring0栈大小
    uint32_t ldt_off;
    uint32_t ldt_size;
};


struct task_struct
{
    uint32_t pid;       // 进程id
    uint32_t status;    // 任务状态
    uint32_t task_base; // 任务地址
    uint32_t counter;   // 运行时间片(剩余时间片)
    uint32_t priority;  // 优先级
    int32_t exit_code;  // 退出代码
};


extern int current_task;

extern uint64_t clock_ticks;

extern struct task_struct tasks[TASK_NR];

extern uint64_t stack0, stack0_top, tss0, ldt0;

extern struct task_img task1_img, task2_img, task3_img, task4_img;

void init_task();

void new_task(struct task_img *img, uint32_t priority);

void do_timer();

void do_schedule();