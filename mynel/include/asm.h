/**
 * 内联汇编宏定义
*/

#include <stdint.h>

extern int timer_interrupt(void);
extern int system_call(void);

#define NULL 0
// 页面分配
extern void *kmalloc_page();
extern void kfree_page(void *addr);


#define kmemset(addr, value, size) 	\
__asm__ ("cld\n"					\
		"rep stosb"					\
		:							\
		:"D" ((uint32_t)(addr)),	\
		 "a" ((uint8_t)(value)),	\
		 "c" ((uint32_t)(size))		\
);

#define kmemcpy(dst, src, size) 	\
__asm__ ("cld\n"					\
		"rep movsb"					\
		:							\
		:"D" ((uint32_t)(dst)),		\
		 "S" ((uint32_t)(src)),		\
		 "c" ((uint32_t)(size))		\
);

extern void move_task0();

#define cli() __asm__ ("cli"::)    // 关中断
#define sti() __asm__ ("sti"::)    // 开中断


#define _set_gate(gate_addr, type, dpl, addr)			\
__asm__ ("movw %%dx,%%ax\n"								\
		"movw %0,%%dx\n"								\
		"movl %%eax,%1\n"								\
		"movl %%edx,%2"									\
		:												\
		: "i" ((short) (0x8000+(dpl<<13)+(type<<8))),	\
		"o" (*((char *) (gate_addr))),					\
		"o" (*(4+(char *) (gate_addr))),				\
		"d" ((char *) (addr)),"a" (0x00080000))

#define set_intr_gate(n, addr)		_set_gate(&idt+n, 14, 0, addr)
#define set_trap_gate(n, addr)		_set_gate(&idt+n, 15, 0, addr)
#define set_system_gate(n, addr) 	_set_gate(&idt+n, 15, 3, addr)

// 硬件端口字节输出
#define io_outb(value, port) \
	__asm__ ("outb %%al,%%dx"::"a" (value),"d" (port))

// 硬件端口字节输入
#define io_inb(port) ({ 											\
	unsigned char _v; 												\
	__asm__ volatile ("inb %%dx,%%al":"=a" (_v):"d" (port));		\
	_v; 															\
	})

#define io_outb_p(value, port) 										\
	__asm__ ("outb %%al,%%dx\n"										\
			"jmp 1f\n"												\
			"1:jmp 1f\n" 											\
			"1:"::"a" (value),"d" (port))

#define io_inb_p(port) ({											\
	unsigned char _v;												\
	__asm__ volatile (												\
		"inb %%dx,%%al\n"											\
		"jmp 1f\n"													\
		"1:jmp 1f\n"												\
		"1:":"=a" (_v):"d" (port));									\
	_v; 															\
	})

// 使用ljmp实现任务切换
#define switch_to(pid) {						\
struct {long a,b;} __tmp; 						\
__asm__(										\
	"movw $0, %0\n"								\
	"movw %%ax,%1\n" 							\
	"ljmp *%0\n" 								\
	::"m" (*&__tmp.a),"m" (*&__tmp.b), 			\
	"a" ((pid)*0x10+0x20)						\
	); 											\
}
