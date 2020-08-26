#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode

if ! grep -q IceKernel /proc/version; then
  touch $MODDIR/remove
  exit 0
fi

echo 1 > /sys/module/icekramel_helper/parameters/is_fod
