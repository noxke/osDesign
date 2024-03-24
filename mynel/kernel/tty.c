/*
 * tty字符功能 
*/

#include <stdint.h>
#include <system.h>
#include <unistd.h>
#include <asm.h>

void tty_init()
{
    // 清空显存
    void *dsp_mem = (void *)p_dsp_info->dsp_mem_addr;
    uint32_t dsp_mem_size = p_dsp_info->dsp_mem_size;
    kmemset(dsp_mem, 0, dsp_mem_size);
    p_dsp_info->cursor_row = 0;
    p_dsp_info->cursur_clm = 0;
}


void draw_chr(int posi, int style, int chr)
{
    sys_call2(__SYS_draw, posi, (style<<8|chr));
}

void draw_str(int posi, int style, char *s)
{
    int psi = posi;
    int p = 0;
    while (s[p] != '\0')
    {
        int chr = s[p];
        sys_call2(__SYS_draw, psi, (style<<8|chr));
        p++;
        psi++;
    }
}