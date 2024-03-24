# build kernel and create mbr Image

# 暂时仅支持x86
ARCH := x86
# 启用mbr引导程序
MBR_LOADER := yes
# 启用调试
DEBUG := yes

CC := gcc
AS := as
AR := ar
LD := ld
NASM := nasm
CFLAGS := -pipe -ffreestanding -nostdlib -fno-pie -fno-stack-protector
LDFLAGS := -nostdlib -z max-page-size=0x1000

ifeq ($(ARCH), x86)
CFLAGS += -m32
LDFLAGS += -m elf_i386
endif

ifeq ($(DEBUG), yes)
CFLAGS += -g
LDFLAGS += -g
endif

export CC
export AS
export AR
export LD
export NASM
export CFLAGS
export LDFLAGS

INCLUDE := $(shell pwd)/include
OUT := $(shell pwd)/out

export ARCH
export MBR_LOADER

export INCLUDE
export OUT


.PHONY: all clean

ifeq ($(MBR_LOADER), yes)
export KERNEL_SIZE

all: prepare Image

Image: kernel.raw
	@make -C bootloader/ KERNEL_SIZE=$(shell stat -c %s $(OUT)/kernel.raw) --no-print-directory
	@dd if=/dev/zero of=$(OUT)/Image bs=512 count=2880 status=none
	@dd if=$(OUT)/bootloader of=$(OUT)/Image bs=512 conv=notrunc status=none
	@dd if=$(OUT)/kernel.raw of=$(OUT)/Image bs=512 seek=4 conv=notrunc status=none

kernel.raw: kernel.bin
	@objcopy -O binary $(OUT)/kernel.bin $(OUT)/kernel.raw

else
all: prepare kernel.bin
endif

prepare:
	@mkdir -p $(OUT)

kernel.bin: kernel_files
	$(LD) $(LDFLAGS) -T linker.ld -o $(OUT)/$@ $(shell find $(OUT) -name *.o)

kernel_files:
	@make -C kernel/ --no-print-directory

clean:
	rm -rf $(OUT)