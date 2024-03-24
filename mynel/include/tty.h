#include <stdint.h>

#define COLOR_BLINK     0b10000000
#define COLOR_BRED      0b01000000
#define COLOR_BGREN     0b00100000
#define COLOR_BBLUE     0b00010000

#define COLOR_LIGHT     0b00001000
#define COLOR_RED       0b00000100
#define COLOR_GREN      0b00000010
#define COLOR_BLUE      0b00000001
#define COLOR_WHITE     0b00000111

void tty_init();

void draw_chr(int posi, int style, int chr);

void draw_str(int posi, int style, char *s);