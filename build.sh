#!/bin/bash

export ARCH=arm64
export CROSS_COMPILE=../build-tools/arm64-gcc/bin/aarch64-elf-
export CROSS_COMPILE_ARM32=../build-tools/arm32-gcc/bin/arm-eabi-
export KJOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"
VERSION="$(cat arch/arm64/configs/sm8150-perf_defconfig | grep "CONFIG_LOCALVERSION\=" | sed -r 's/.*"(.+)".*/\1/' | sed 's/^.//')"

echo
echo "Compiling Kernel"
echo
make sm8150-perf_defconfig
make -j${KJOBS} || exit 1

if [ -e arch/arm64/boot/Image.gz ] ; then
	echo
	echo "Building Kernel Package"
	echo
	mkdir kernelzip
	mkdir kernelzip/source
	cp -rp ./anykernel/* kernelzip/
	cp arch/arm64/boot/Image.gz kernelzip/source/
	find arch/arm64/boot/dts -name '*.dtb' -exec cat {} + > kernelzip/source/dtb
	cd kernelzip
	7z a -mx9 $VERSION-tmp.zip *
	zipalign -v 4 $VERSION-tmp.zip ../$VERSION.zip
	rm $VERSION-tmp.zip
	cd ..
	ls -al $VERSION.zip
fi

if [[ "${1}" == "upload" ]]; then
	echo
	echo "Uploading"
	echo
    md5sum $VERSION.zip
    echo
	curl -sL https://git.io/file-transfer | sh
	./transfer wet $VERSION.zip
fi
