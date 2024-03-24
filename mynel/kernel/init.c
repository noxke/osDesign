/*
 * 内核初始化
*/

#include <stdint.h>
#include <asm.h>
#include <system.h>
#include <unistd.h>
#include <task.h>
#include <tty.h>

// 扩展内存大小
uint16_t *pextern_mem;

// 显示器信息
struct _dsp_info *p_dsp_info;

// 软盘信息
struct _floppy_info *boot_drive;

// global vars
uint32_t mem_size;
uint32_t mem_start;
uint32_t mem_end;

void init();

void init_global_var()
{
    pextern_mem = (uint16_t *)0x90000;
    p_dsp_info = (struct _dsp_info *)0x90002;
    boot_drive = (struct _floppy_info *)0x90100;
    mem_size = ((uint32_t)*pextern_mem + 1024) << 10;
    mem_start = 0x100000;   // 可用内存从1M开始
    mem_end = mem_size;
}

void mem_init()
{
    // 将0~mem_end内存页标记为存在
    // 将mem_end~64M内存页标记为不存在
    // 将0~mem_start内存页标记为使用
    // 将mem_start~mem_end内存页标记为未使用
    uint32_t *pg_frame = (uint32_t *)0x1000;
    for (uint32_t i = 0; i < 0x4000; i++)
    {
        if (i < (mem_start >> 12))
        {
            // 存在 可读写 已使用
            *(uint8_t *)(pg_frame+i) = 0b100111;
        }
        else if (i < (mem_end >> 12))
        {
            // 存在 可读写 未使用
            *(uint8_t *)(pg_frame+i) = 0b000111;
        }
        else
        {
            // 不存在
            *(uint8_t *)(pg_frame+i) = 0b000000;
        }
    }
}

// 中断平频率100hz 10ms
#define HZ 100
#define CLOCK_TICK_RATE 1193180
#define LATCH (CLOCK_TICK_RATE/HZ)

void intr_init()
{
    // 开启时钟中断
    io_outb_p(0x36, 0x43);  // 设置定时器
    io_outb_p(LATCH & 0xff, 0x40);
    io_outb(LATCH >> 8, 0x40);

    set_intr_gate(0x20, &timer_interrupt);
    io_outb(io_inb_p(0x21)&0xFE, 0x21); // 开启8259定时器中断
    // 系统中断
    set_system_gate(0x80, &system_call);
}

void main()
{
    init_global_var();  // 初始化全局变量
    mem_init();     // 初始化内存 设置页表状态
    tty_init();     // 初始化tty (暂时只做字符输出)
    intr_init();    // 中断初始化
    init_task();    // 任务初始化
    sti();              // 开启中断

    new_task(&task1_img, 16);
    new_task(&task2_img, 10);
    new_task(&task3_img, 8);
    new_task(&task4_img, 6);

    move_task0();       // 开启ldr 切换到任务0
    init();
    for (;;)
    {
        sys_call0(__SYS_sche);
    }
}

// init() 为task0执行的任务
void init()
{
    char mem_size_s[32]     = {"MEM_SIZE:  0x00000000 Byte"};
    char mem_begin_s[32]    = {"MEM_BEGIN: 0x00000000 Byte"};
    char mem_end_s[32]      = {"MEM_END:   0x00000000 Byte"};
    for (int i = 0; i < 8; i++)
    {
        char sz, bg, ed;
        sz = mem_size   >> (28 - 4 * i) & 0xF;
        bg = mem_start  >> (28 - 4 * i) & 0xF;
        ed = mem_end    >> (28 - 4 * i) & 0xF;
        sz += (sz >= 10) ? 55 : 48;
        bg += (bg >= 10) ? 55 : 48;
        ed += (ed >= 10) ? 55 : 48;
        mem_size_s[i+13]    = sz;
        mem_begin_s[i+13]   = bg;
        mem_end_s[i+13]     = ed;
    }
    draw_str(0x0000, COLOR_WHITE, mem_size_s);
    draw_str(0x0100, COLOR_WHITE, mem_begin_s);
    draw_str(0x0200, COLOR_WHITE, mem_end_s);
}