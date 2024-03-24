#!/bin/sh

# run bochs in xserver
export DISPLAY=:1.0

export BOCHS_PATH=$(dirname `realpath $0`)/bochs
export KERNEL_PATH=$(dirname `realpath $0`)/mynel


if [ "$1" ] && [ "$1" = "-m" ]
then
    cd $KERNEL_PATH
    make
    cp "$KERNEL_PATH/out/Image" "$BOCHS_PATH/Image"
    cp "$KERNEL_PATH/out/kernel.bin" "$BOCHS_PATH/kernel.bin"
    make clean
    cd $BOCHS_PATH
elif [ "$1" ] && [ "$1" = "-gr" ]
then
    # i8086模式调试
    bochs -q -f $BOCHS_PATH/bochsrc-gdb.bxrc & \
    gdb -x $BOCHS_PATH/gdbrc-realmode -ix $BOCHS_PATH/gdb_init_real_mode.txt
elif [ "$1" ] && [ "$1" = "-g" ]
then
    # i386模式调试
    bochs -q -f $BOCHS_PATH/bochsrc-gdb.bxrc & \
    gdb -x $BOCHS_PATH/gdbrc $BOCHS_PATH/kernel.bin
elif [ "$1" ] && [ "$1" = "-d" ]
then
    # bochs调试
    bochs-dbg -q -f $BOCHS_PATH/bochsrc.bxrc
else
    bochs -q -f $BOCHS_PATH/bochsrc.bxrc
fi

pkill bochs
