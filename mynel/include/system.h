// 扩展内存大小
#include <stdint.h>

extern uint16_t *pextern_mem;

// 显示器信息
struct _dsp_info {
    uint32_t dsp_mem_addr;  // 显存地址
    uint16_t dsp_mem_size;  // 显存大小
    uint8_t cursur_clm; // 光标所在列数
    uint8_t cursor_row; // 光标所在行数
    uint8_t dsp_clm;    // 显示器列数
    uint8_t dsp_row;    // 显示器行数
    uint16_t dsp_page;  // 显示页面
    uint8_t dsp_mode;   // 显示模式
    uint8_t char_clm;   // 字符列数
};
extern struct _dsp_info *p_dsp_info;

// 软盘信息
struct _floppy_info
{
    uint8_t driver_nr;  // 驱动器数
    uint8_t header_nr;  // 驱动器磁头数
    uint16_t sector_nr; // 每磁道扇区数
    uint16_t track_nr;  // 磁道数
};
extern struct _floppy_info *boot_drive;

// global vars
extern uint32_t mem_size;
extern uint32_t mem_start;
extern uint32_t mem_end;

extern uint64_t idt;
extern uint64_t gdt;
