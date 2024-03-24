src_asm = $(wildcard *.s)

src_files = $(src_asm)

obj_files = $(patsubst %s, %o, $(src_asm))

all: $(obj_files)
	@mv $(obj_files) -t $(OUT)/kernel

%.o: %.s
	$(CC) $(CFLAGS) -c $< -I $(INCLUDE) -o $@