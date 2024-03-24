#define __SYS_draw 0xFF01
#define __SYS_sche 0xFF02

#define sys_call0(__NR) {                           \
    long __res;                                     \
    __asm__ (                                       \
        "int $0x80\n"                               \
        : "=a" (__res)                              \
        : "a" (__NR)                                \
    );                                              \
}

#define sys_call1(__NR, arg0) {                     \
    long __res;                                     \
    __asm__ (                                       \
        "int $0x80\n"                               \
        : "=a" (__res)                              \
        : "a" (__NR),                               \
        "b" (arg0)                                  \
    );                                              \
}

#define sys_call2(__NR, arg0, arg1) {               \
    long __res;                                     \
    __asm__ (                                       \
        "int $0x80\n"                               \
        : "=a" (__res)                              \
        : "a" (__NR),                               \
        "b" (arg0),                                 \
        "c" (arg1)                                  \
    );                                              \
}

