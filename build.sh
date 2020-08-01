#!/bin/bash

export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=../build-tools/arm64-gcc/bin/aarch64-elf-
export CROSS_COMPILE_ARM32=../build-tools/arm32-gcc/bin/arm-eabi-
export KBUILD_BUILD_USER=misaka
export KBUILD_BUILD_HOST=tp-workstation
export KJOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"
VERSION="$(cat defconfig | grep "CONFIG_LOCALVERSION\=" | sed -r 's/.*"(.+)".*/\1/' | sed 's/^.//' | sed 's/^..........//')"

echo
echo "Compiling Kernel"
echo
cp defconfig .config
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
	7z a -mx9 airKernel-$VERSION-tmp.zip *
	zipalign -v 4 airKernel-$VERSION-tmp.zip ../airKernel-$VERSION.zip
	rm airKernel-$VERSION-tmp.zip
	cd ..
	ls -al airKernel-$VERSION.zip
fi

if [[ "${1}" == "upload" ]]; then
	echo
	echo "Uploading"
	echo
	curl -sL https://git.io/file-transfer | sh
	./transfer bit airKernel-$VERSION.zip
fi
