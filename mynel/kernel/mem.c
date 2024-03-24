/**
 * 页面分配与回收
*/

#include <stdint.h>
#include <asm.h>
#include <system.h>

void *kmalloc_page()
{
    void * ret_pg = NULL;
    uint32_t pg_start = mem_start >> 12;
    uint32_t pg_end = mem_end >> 12;
    for (uint32_t i = pg_start; i < pg_end; i++)
    {
        uint32_t *pg_addr = (uint32_t *)(i * 4 + 0x1000);
        if ((*pg_addr & 0b001) && (!(*pg_addr & 0b00100000)))
        {
            // 找到存在且未使用页面返回
            *pg_addr |= 0b00100000;  // 将页标记为使用
            ret_pg = (void *)(((uint32_t)pg_addr - 0x1000) << 10);
            break;
        }
    }
    return ret_pg;
}

void kfree_page(void *addr)
{
    if ((uint32_t)addr < mem_start)
    {
        return;
    }
    uint32_t pg_nr = (uint32_t)addr >> 12;
    uint32_t *pg_addr = (uint32_t *)(pg_nr * 4 + 0x1000);
    *(uint8_t *)pg_addr &= 0b11011111;    // 置为 存在 可读写 未使用
}