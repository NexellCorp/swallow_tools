#!/bin/bash

CURRENT_PATH=`dirname $0`
TOOLS_PATH=`readlink -ev $CURRENT_PATH`
ROOT_PATH=`readlink -ev ${TOOLS_PATH}/..`

argc=$#

BUILD_PATH=

TOOLCHAIN_PATH="${HOME}/riscv-toolchain"

FIRST_BUILD=false
CLEAN_BUILD=false

BUILD_ALL=true
BUILD_BL1=false
BUILD_PK=false
BUILD_KERNEL=false

BL1_PATH=`readlink -ev ${ROOT_PATH}/riscv-bl1/`

PK_PATH=`readlink -ev ${ROOT_PATH}/riscv-pk/`
PK_PAYLOAD_ENABLE=false

KERNEL_PATH=`readlink -ev ${ROOT_PATH}/riscv-linux/`
KERNEL_DEFCONFIG=defconfig
KERNEL_ARCH=riscv

set -e

function parse_args()
{
    ARGS=$(getopt -o cft:h -- "$@");
    eval set -- "$ARGS";

    while true; do
        case "$1" in
            -c ) CLEAN_BUILD=true; shift 1 ;;
	    -f ) FIRST_BUILD=true; shift 1 ;;
	    -t ) case "$2" in
		     bl1    ) BUILD_ALL=false; BUILD_BL1=true ;;
		     pk     ) BUILD_ALL=false; BUILD_PK=true ;;
		     kernel ) BUILD_ALL=false; BUILD_KERNEL=true ;;
		     *      ) usage; exit 1 ;;
		 esac
		 shift 2 ;;
	    -h ) usage; exit 1 ;;
            -- ) break ;;
        esac
    done
}

function usage()
{
    echo -e "\nUsage: $0 [-c -f -t bl1 -t pk -t kernel] \n"
    echo -e " : default, total build, none argument"    
    echo -e " -f : first build"
    echo -e " -c : cleanbuild"
    echo -e " -t bl1    : if you want to build only bl1, specify this, default no"
    echo -e " -t pk     : if you want to build only pk, specify this, default no"
    echo -e " -t kernel : if you want to build only kernel, specify this, default no"
    echo " ex) $0 "
    echo " ex) $0 -f"
    echo " ex) $0 -t pk"
    echo " ex) $0 -t bl1 -t pk"
    echo ""
}

function environment_check()
{
    if [ -d ${TOOLCHAIN_PATH} ]; then
        echo "Toolchain exist"
        TOOLCHAIN_PATH=`readlink -ev ${HOME}/riscv-toolchain`
        export RISCV=${TOOLCHAIN_PATH}
        export PATH=$PATH:$RISCV/bin
    else
        echo "toolchain does not installed, Plesae check toolchain or have to first build"
        usage
        exit 1
    fi
}

function do_build()
{
    echo -e "\n\033[45;30m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[45;30m              ---------  Build Start ---------                      \033[0m"
    echo -e "\033[45;30m ------------------------------------------------------------------ \033[0m"

    if [ ! -d ${ROOT_PATH}/build ];then
        mkdir -p ${ROOT_PATH}/build        
    fi
    BUILD_PATH=`readlink -ev ${ROOT_PATH}/build`
        
    if [ ${FIRST_BUILD} == true ];then
        echo -e "\033[45;30m First Build !\033[0m"
        toolchain_build
        qemu_build
        bl1_build
        kernel_build
        pk_build
    else
        environment_check
        if [ $BUILD_ALL == true ];then
            echo -e "\033[45;30m All Build !\033[0m"
            bl1_build
            kernel_build
            pk_build
        else
            echo -e "\033[45;30m Partital Build !\033[0m"
            if [ $BUILD_BL1 == true ];then
                bl1_build
            fi
            if [ $BUILD_PK == true ];then
                pk_build
            fi
            if [ $BUILD_KERNEL == true ];then
                kernel_build
            fi        
        fi
    fi
}

function toolchain_build()
{
    echo -e "\n\033[45;30m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[45;30m                      ToolChain Build                               \033[0m"
    echo -e "\033[45;30m ------------------------------------------------------------------ \033[0m"
    ${TOOLS_PATH}/riscv-tools-setup.sh
}

function qemu_build()
{
    echo -e "\n\033[46;30m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[46;30m                         QEMU Build                                 \033[0m"
    echo -e "\033[46;30m ------------------------------------------------------------------ \033[0m"
    ${TOOLS_PATH}/riscv-qemu-setup.sh
}

function bl1_build()
{
    echo -e "\n\033[45;30m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[45;30m                         Bl1 Build                                  \033[0m"
    echo -e "\033[45;30m ------------------------------------------------------------------ \033[0m"
    pushd ${BL1_PATH}/bl1
    ./run.sh
    popd

    pushd ${BL1_PATH}/vector
    ./run.sh
    popd    
}

function pk_build()
{
    echo -e "\n\033[46;30m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[46;30m                         BBL(PK) Build                              \033[0m"
    echo -e "\033[46;30m ------------------------------------------------------------------ \033[0m"

    pushd ${PK_PATH}

    if [ $CLEAN_BUILD == true ];then
        rm -rf build
        mkdir -p build
    fi

    pushd build

    if [ $PK_PAYLOAD_ENABLE == true ]; then
        ../configure --prefix=$RISCV --host=riscv64-unknown-elf --with-payload=${KERNEL_PATH}/vmlinux
    else
        ../configure --prefix=$RISCV --host=riscv64-unknown-elf
    fi

    make clean
    make

    riscv64-unknown-elf-objcopy -O binary bbl bbl.bin

    #    make install

    popd #build
    popd #riscv-pk
}

function kernel_build()
{
    echo -e "\n\033[45;30m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[45;30m                         Kernel Build                               \033[0m"
    echo -e "\033[45;30m ------------------------------------------------------------------ \033[0m"
    
    pushd ${KERNEL_PATH}

    if [ $CLEAN_BUILD == true ];then
        make clean
    fi

    make ARCH=${KERNEL_ARCH} ${KERNEL_DEFCONFIG}

    make ARCH=${KERNEL_ARCH} CROSS_COMPILE=${RISCV}/bin/riscv64-unknown-elf- vmlinux
}

function move_images()
{
    echo -e "\n\033[46;30m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[46;30m                         Move Images                                \033[0m"
    echo -e "\033[46;30m ------------------------------------------------------------------ \033[0m"

    echo -e "\033[45;30m     Copy bl1.bin ---->        \033[0m"
    cp ${BL1_PATH}/bl1/build/bl1.bin ${BUILD_PATH}

    echo -e "\033[45;30m     Copy vector.bin ---->        \033[0m"
    cp ${BL1_PATH}/vector/build/vector.bin ${BUILD_PATH}

    echo -e "\033[45;30m     Copy vmlinux ---->        \033[0m"
    cp ${KERNEL_PATH}/vmlinux ${BUILD_PATH}

    echo -e "\033[45;30m     Copy bbl.bin ---->        \033[0m"
    cp ${PK_PATH}/build/bbl.bin ${BUILD_PATH}

    echo -e "\033[45;30m     Copy swallow.dtb ---->        \033[0m"
    cp ${TOOLS_PATH}/bootgen/swallow.dtb ${BUILD_PATH}
}

function convert_images()
{
    echo -e "\n\033[45;30m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[45;30m                         Convert Images                             \033[0m"
    echo -e "\033[45;30m ------------------------------------------------------------------ \033[0m"

    pushd ${TOOLS_PATH}/bootgen
    
    ./makebingen.sh dos ${BUILD_PATH}

    popd
}

parse_args $@

#BUILD_PATH=`readlink -ev ${ROOT_PATH}/build`
do_build
move_images
convert_images
