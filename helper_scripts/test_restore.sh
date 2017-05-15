#!/bin/ash
# this script is used to test the behavior of wireless adapter after
# force_quiet_bit is cleared (i.e. how soon the adapter will resume transmission
# after we clear the "fake" channel occupied message)
# <delay> is in us, indicating how soon the driver will start to interrupt
# transmission after a frame is passed to the adapter hardware
# [count] is the number of packets to test
# [duration] is in us, indicating how long the interrupt will be put (i.e. the
# driver will stop interrupting transmission after [duration] time.

delay=$1
count=$2
delay_between_set_clear=$3

if [ -z $delay ]; then
	echo "usage: $0 <delay> [count] [duration]"
	exit
fi

if [ -z $count ]; then
	count=1
fi

if [ -z $delay_between_set_clear ]; then
	delay_between_set_clear=0
fi

#enable timing debug output
echo 0x00100400 > /sys/kernel/debug/ieee80211/phy0/ath9k/debug
#tell driver to resume transmission after interrupting it
echo 1 > /sys/kernel/debug/ieee80211/phy0/ath9k/force_quiet_bit_restore
#set the delay of initialating the TX interrupt
echo $delay > /sys/kernel/debug/ieee80211/phy0/ath9k/force_quiet_bit_delay
#set the duration of interrupt
echo $delay_between_set_clear > /sys/kernel/debug/ieee80211/phy0/ath9k/force_quiet_bit_restore_in
#tell driver to printk output after processing [count] packets
echo $count > /sys/kernel/debug/ieee80211/phy0/ath9k/max_timing_count
#use packet injector to send [count] packets
/root/packetspammer -c $count mon0 -d0
#wait for possible delays in executing printk
sleep 1
#print kernel debug information, where the test result will be put
dmesg -c
#clean up
echo 0 > /sys/kernel/debug/ieee80211/phy0/ath9k/force_quiet_bit_delay
echo 0 > /sys/kernel/debug/ieee80211/phy0/ath9k/force_quiet_bit_restore_in
