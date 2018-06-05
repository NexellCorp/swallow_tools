#!/bin/bash

cd riscv-pk
mkdir -p build
cd build

export RISCV=${HOME}/riscv-toolchain/
export PATH=$PATH:$RISCV/bin
../configure --prefix=$RISCV --host=riscv64-unknown-elf
make
make install
