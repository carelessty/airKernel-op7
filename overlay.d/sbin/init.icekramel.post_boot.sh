#! /vendor/bin/sh

# Workaround vdc slowing down boot
( for i in $(seq 1 20); do
    PID=$(pgrep -f "vdc checkpoint restoreCheckpoint")
    if [ ! -z $PID ]; then
      echo "Killing checkpoint vdc process $PID"
      kill -9 $PID
      exit
    fi
    sleep 1
  done
  echo "Timed out while looking for checkpoint vdc process"
) &

# Replace msm_irqbalance.conf
echo "PRIO=1,1,1,1,0,0,0,0
#arch_timer, arm-pmu, arch_mem_timer, msm_drm, glink_lpass, kgsl
IGNORED_IRQ=19,21,38,115,188,332" > /dev/msm_irqbalance.conf
chmod 644 /dev/msm_irqbalance.conf
mount --bind /dev/msm_irqbalance.conf /vendor/etc/msm_irqbalance.conf
chcon "u:object_r:vendor_configs_file:s0" /vendor/etc/msm_irqbalance.conf
killall msm_irqbalance

# Setup readahead
find /sys/devices -name read_ahead_kb | while read node; do echo 128 > $node; done

# Setting b.L scheduler parameters
echo 95 95 > /proc/sys/kernel/sched_upmigrate
echo 85 85 > /proc/sys/kernel/sched_downmigrate

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
fi

# Restore UFS Powersave
echo 1 > /sys/devices/platform/soc/1d84000.ufshc/clkgate_enable
echo 1 > /sys/devices/platform/soc/1d84000.ufshc/hibern8_on_idle_enable
# Restore lpm_level
echo N > /sys/module/lpm_levels/parameters/sleep_disabled

# blkio tweaks
echo 2000 > /dev/blkio/blkio.group_idle
echo 0 > /dev/blkio/background/blkio.group_idle
echo 1000 > /dev/blkio/blkio.weight
echo 200 > /dev/blkio/background/blkio.weight

# vm tweaks
echo 10 > /proc/sys/vm/dirty_background_ratio
echo 3000 > /proc/sys/vm/dirty_expire_centisecs
echo 0 > /proc/sys/vm/page-cluster

