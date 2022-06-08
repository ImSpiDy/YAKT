#!/system/bin/sh
# Yakt v2
# By @NotZeetaa (Github)

sleep 60

SC=/sys/devices/system/cpu/cpu0/cpufreq/schedutil
KP=/sys/module/kprofiles
LOG=/sdcard/yakt.log
TP=/dev/stune/top-app/uclamp.max
DV=/dev/stune
CP=/dev/cpuset
MC=/sys/module/mmc_core
WT=/proc/sys/vm/watermark_boost_factor
KL=/proc/sys/kernel
VM=/proc/sys/vm
S2=/sys/devices/system/cpu/cpufreq/schedutil

PS=$(cat /proc/version)
BT=$(getprop ro.boot.bootdevice)

echo "# YAKT v2" > $LOG
echo "# Build Date: 08/06/2022" >> $LOG
echo "# By @NotZeetaa (Github)" >> $LOG
echo " " >> $LOG
echo "$(date "+%H:%M:%S") * Device: $(getprop ro.product.system.model)" >> $LOG
echo "$(date "+%H:%M:%S") * Kernel: $(uname -r)" >> $LOG
echo "$(date "+%H:%M:%S") * Android Version: $(getprop ro.system.build.version.release)" >> $LOG
echo " " >> $LOG

# Use Google's schedutil rate-limits from Pixel 3
# Credits to Kdrag0n
echo "$(date "+%H:%M:%S") * Applying Google's schedutil rate-limits from Pixel 3" >> $LOG
sleep 0.5
if [ -d $S2 ]; then
  echo 1000 > $S2/up_rate_limit_us
  echo 20000 > "${cpu}"/down_rate_limit_us
  echo "$(date "+%H:%M:%S") * Applied Google's schedutil rate-limits from Pixel 3" >> $LOG
  echo " " >> $LOG
else
  if [ -e $SC ]; then
  for cpu in /sys/devices/system/cpu/*/cpufreq/schedutil
  do
    echo 1000 > "${cpu}"/up_rate_limit_us
    echo 20000 > "${cpu}"/down_rate_limit_us
  done
    echo "$(date "+%H:%M:%S") * Applied Google's schedutil rate-limits from Pixel 3" >> $LOG
  else
    echo "$(date "+%H:%M:%S") * Abort You are not using schedutil governor" >> $LOG
  fi
  echo " " >> $LOG
fi
  
# (Rewrited) Tweaks to have less Latency
# Credits to RedHat & tytydraco
echo "$(date "+%H:%M:%S") * Tweaking to Reduce Latency " >> $LOG
echo 16000000 > $KL/sched_wakeup_granularity_ns
echo 10000000 > $KL/sched_min_granularity_ns
echo 4000000 > $KL/sched_migration_cost_ns
sleep 0.5
echo "$(date "+%H:%M:%S") * Done " >> $LOG
echo " " >> $LOG

# Kprofiles Tweak
# Credits to cyberknight
echo "$(date "+%H:%M:%S") * Checking if your kernel has Kprofiles support..." >> $LOG
if [ -d $KP ]; then
  echo "$(date "+%H:%M:%S") * Your Kernel Supports Kprofiles" >> $LOG
  echo "$(date "+%H:%M:%S") * Tweaking it..." >> $LOG
  sleep 0.5
  echo "$(date "+%H:%M:%S") * Done" >> $LOG
  echo 2 > $KP/parameters/mode
else
  echo "$(date "+%H:%M:%S") * Your Kernel doesn't support Kprofiles" >> $LOG
fi
echo " " >> $LOG

# Less Ram Usage
# The stat_interval one, reduces jitter (Credits to kdrag0n)
# Credits to RedHat for dirty_ratio
echo "$(date "+%H:%M:%S") * Applying Ram Tweaks" >> $LOG
sleep 0.5
echo 50 > $VM/vfs_cache_pressure
echo 10 > $VM/stat_interval
echo "$(date "+%H:%M:%S") * Applied Ram Tweaks" >> $LOG
echo " " >> $LOG

# Set kernel.perf_cpu_time_max_percent to 15
echo "$(date "+%H:%M:%S") * Applying tweak for perf_cpu_time_max_percent" >> $LOG
echo 15 > $KL/perf_cpu_time_max_percent
echo "$(date "+%H:%M:%S") * Done" >> $LOG
echo " " >> $LOG

# Disable some scheduler logs/stats
# Also iostats & reduce latency
# Credits to tytydraco
echo "$(date "+%H:%M:%S") * Disabling some scheduler logs/stats" >> $LOG
if [ -e $KL/sched_schedstats ]; then
  echo 0 > $KL/sched_schedstats
fi
echo off > $KL/printk_devkmsg
for queue in /sys/block/*/queue
do
    echo 0 > "$queue/iostats"
    echo 32 > "$queue/nr_requests"
done
echo "$(date "+%H:%M:%S") * Done" >> $LOG
echo " " >> $LOG

# Disable Timer migration
echo "$(date "+%H:%M:%S") * Disabling Timer Migration" >> $LOG
echo 0 > $KL/timer_migration
echo "$(date "+%H:%M:%S") * Done" >> $LOG
echo " " >> $LOG

# Cgroup Boost
echo "$(date "+%H:%M:%S") * Checking which scheduler your kernel has" >> $LOG
sleep 0.5
if [ -e $TP ]; then
  # Uclamp Tweaks
  # All credits to @darkhz
  echo "$(date "+%H:%M:%S") * You have uclamp scheduler" >> $LOG
  echo "$(date "+%H:%M:%S") * Applying tweaks for it" >> $LOG
  sleep 0.3
  for ta in $CP/*/top-app
  do
      echo max > "$ta/uclamp.max"
      echo 10 > "$ta/uclamp.min"
      echo 1 > "$ta/uclamp.boosted"
      echo 1 > "$ta/uclamp.latency_sensitive"
  done
  for fd in $CP/*/foreground
  do
      echo 50 > "$fd/uclamp.max"
      echo 0 > "$fd/uclamp.min"
      echo 0 > "$fd/uclamp.boosted"
      echo 0 > "$fd/uclamp.latency_sensitive"
  done
  for bd in $CP/*/background
  do
      echo max > "$bd/uclamp.max"
      echo 20 > "$bd/uclamp.min"
      echo 0 > "$bd/uclamp.boosted"
      echo 0 > "$bd/uclamp.latency_sensitive"
  done
  for sb in $CP/*/system-background
  do
      echo 40 > "$sb/uclamp.max"
      echo 0 > "$sb/uclamp.min"
      echo 0 > "$sb/uclamp.boosted"
      echo 0 > "$sb/uclamp.latency_sensitive"
  done
  sysctl -w kernel.sched_util_clamp_min_rt_default=96
  sysctl -w kernel.sched_util_clamp_min=128
  echo "$(date "+%H:%M:%S") * Done" >> $LOG
  echo " " >> $LOG
else
  echo "$(date "+%H:%M:%S") * You have normal cgroup scheduler" >> $LOG
  echo "$(date "+%H:%M:%S") * Applying tweaks for it" >> $LOG
  sleep 0.3
  chmod 644 $DV/top-app/schedtune.boost
  echo 0 > $DV/top-app/schedtune.boost
  chmod 664 $DV/top-app/schedtune.boost
  echo 0 > $DV/top-app/schedtune.prefer_idle
  echo 1 > $DV/foreground/schedtune.boost
  echo 0 > $DV/background/schedtune.boost
  echo "$(date "+%H:%M:%S") * Done" >> $LOG
  echo " " >> $LOG
fi

# ipv4 tweaks
# Reduce Net Ipv4 Performance Spikes
# By @Panchajanya1999
echo 0 > /proc/sys/net/ipv4/tcp_timestamps
chmod 444 /proc/sys/net/ipv4/tcp_timestamps

# Enable ECN negotiation by default
# By kdrag0n
echo 1 > /proc/sys/net/ipv4/tcp_ecn

# Always allow sched boosting on top-app tasks
# Credits to tytydraco
echo "$(date "+%H:%M:%S") * Always allow sched boosting on top-app tasks" >> $LOG
echo 0 > $KL/sched_min_task_util_for_colocation
echo "$(date "+%H:%M:%S") * Done" >> $LOG
echo " " >> $LOG

# Watermark Boost Tweak
echo "$(date "+%H:%M:%S") * Checking if you have watermark boost support" >> $LOG
if [[ "$PS" == *"4.19"* ]]
then
  echo "$(date "+%H:%M:%S") * Found 4.19 kernel, disabling watermark boost because doesn't work..." >> $LOG
  echo 0 > $VM/watermark_boost_factor
  echo "$(date "+%H:%M:%S") * Done!" >> $LOG
elif [ -e $WT ]; then
  echo "$(date "+%H:%M:%S") * Found Watermark Boost support, tweaking it" >> $LOG
  echo 1500 > $WT
  echo "$(date "+%H:%M:%S") * Done!" >> $LOG
else
  echo "$(date "+%H:%M:%S") * Your kernel doesn't support watermark boost" >> $LOG
  echo "$(date "+%H:%M:%S") * Aborting it..." >> $LOG
  echo "$(date "+%H:%M:%S") * Done!" >> $LOG
fi
echo " " >> $LOG

echo "$(date "+%H:%M:%S") * Tweaking read_ahead overall" >> $LOG
for queue2 in /sys/block/*/queue/read_ahead_kb
do
echo 128 > $queue2
done
echo "$(date "+%H:%M:%S") * Tweaked read_ahead" >> $LOG
echo " " >> $LOG

# UFSTW (UFS Turbo Write Tweak)
echo "$(date "+%H:%M:%S") * Checking if your kernel has UFS Turbo Write Support" >> $LOG
if [ -e /sys/devices/platform/soc/$BT/ufstw_lu0/tw_enable ]; then
  echo "$(date "+%H:%M:%S") * Your kernel has UFS Turbo Write Support. Tweaking it..." >> $LOG
  echo 1 > /sys/devices/platform/soc/$BT/ufstw_lu0/tw_enable
  echo "$(date "+%H:%M:%S") * Done!" >> $LOG
else
  echo "$(date "+%H:%M:%S") * Your kernel doesn't have UFS Turbo Write Support." >> $LOG
fi
echo " " >> $LOG

# Extfrag
# Credits to @tytydraco
echo "$(date "+%H:%M:%S") * Increasing fragmentation index" >> $LOG
echo 750 > $VM/extfrag_threshold
sleep 0.5
echo "$(date "+%H:%M:%S") * Done!" >> $LOG
echo " " >> $LOG

# Disable Spi CRC
if [ -d $MC ]; then
  echo "$(date "+%H:%M:%S") * Disabling Spi CRC" >> $LOG
  echo 0 > $MC/parameters/use_spi_crc
  echo "$(date "+%H:%M:%S") * Done!" >> $LOG
  echo " " >> $LOG
else
  :
fi

echo "$(date "+%H:%M:%S") * The Tweak is done enjoy :)" >> $LOG
