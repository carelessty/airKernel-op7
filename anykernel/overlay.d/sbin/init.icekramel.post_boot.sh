#! /vendor/bin/sh

# Replace msm_irqbalance.conf
echo "PRIO=1,1,1,1,0,0,0,0
#arch_timer, arm-pmu, arch_mem_timer, msm_drm, glink_lpass, kgsl
IGNORED_IRQ=19,21,38,115,188,332" > /dev/msm_irqbalance.conf
chmod 644 /dev/msm_irqbalance.conf
mount --bind /dev/msm_irqbalance.conf /vendor/etc/msm_irqbalance.conf
chcon "u:object_r:vendor_configs_file:s0" /vendor/etc/msm_irqbalance.conf
killall msm_irqbalance

# Setup vbswap
while [ ! -e /dev/block/vbswap0 ]; do
  sleep 1
done
if ! grep -q vbswap /proc/swaps; then
  # 4GB
  echo 4294967296 > /sys/devices/virtual/block/vbswap0/disksize
  # Set swappiness reflecting the device's RAM size
  RamStr=$(cat /proc/meminfo | grep MemTotal)
  RamMB=$((${RamStr:16:8} / 1024))
  if [ $RamMB -le 6144 ]; then
    echo 190 > /proc/sys/vm/rswappiness
  elif [ $RamMB -le 8192 ]; then
    echo 160 > /proc/sys/vm/rswappiness
  else
    echo 130 > /proc/sys/vm/rswappiness
  fi
  mkswap /dev/block/vbswap0
  swapon /dev/block/vbswap0
  echo 0 > /sys/block/vbswap0/queue/read_ahead_kb
fi

# blkio tweaks
echo 2000 > /dev/blkio/blkio.group_idle
echo 0 > /dev/blkio/background/blkio.group_idle
echo 1000 > /dev/blkio/blkio.weight
echo 200 > /dev/blkio/background/blkio.weight

# vm tweaks
echo 10 > /proc/sys/vm/dirty_background_ratio
echo 3000 > /proc/sys/vm/dirty_expire_centisecs
echo 0 > /proc/sys/vm/page-cluster

# net tweaks
echo 262144 > /proc/sys/net/core/rmem_max
echo 262144 > /proc/sys/net/core/wmem_max

echo 0 > /sys/module/dm_verity/parameters/prefetch_cluster
