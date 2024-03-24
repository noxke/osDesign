all:
ifeq ($(ARCH), x86)
	$(NASM) -f bin -d KERNEL_SZ=$(KERNEL_SIZE) -o mbrloader mbrloader.asm
	$(NASM) -f bin -d KERNEL_SZ=$(KERNEL_SIZE) -o setup setup.asm
	@dd if=mbrloader of=bootloader bs=512 count=1 conv=sync status=none
	@dd if=setup of=bootloader bs=512 seek=1 conv=sync status=none
	@rm mbrloader setup
	@mv bootloader $(OUT)
else
	@echo "unsupported arch"
	@false
endif