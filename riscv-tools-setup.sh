#!/bin/bash

mkdir -p ${HOME}/riscv-toolchain

cd riscv-tools
git submodule update --init --recursive
export RISCV=${HOME}/riscv-toolchain/
export PATH=$PATH:$RISCV/bin

./build.sh
