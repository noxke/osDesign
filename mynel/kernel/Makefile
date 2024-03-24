src_files = $(wildcard *.c)
obj_files = $(notdir $(patsubst %c, %o, $(src_files)))

all:
ifeq ($(ARCH), x86)
	@mkdir -p $(OUT)/kernel
	@make -C asm/ --no-print-directory
	$(CC) $(CFLAGS) -c $(src_files) -I $(INCLUDE)
	@mv $(obj_files) -t $(OUT)/kernel
else
	@echo "unsupported arch"
	@false
endif