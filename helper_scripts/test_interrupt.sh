#!/bin/ash
# this script is used to test whether force quiet bit will interrupt 
# transmission immediately
# <delay of interrupt> is in us, indicating how soon the force_quiet_bit will
# be set and cleared once the driver put a frame into the wireless adapter
# [count] is the number of test to do
#
# reminder: set delay to 0us is a good way to observe the transmission behavior
#           of the wirelee adapter
#           set delay to any value greater than 0 will force count=1, the
#           desired behavior is to observe a packet stuck in the TX queue if
#           the interrupt of transmission is successful

delay=$1
packet_num=$2

if [ -z $delay ]; then
	echo "usage: $0 <delay of interrupt> [count]"
	exit
fi

if [ -z $packet_num -o $delay -gt 0 ] ; then
	packet_num=1
fi

#enable timing debug output
echo 0x00100400 > /sys/kernel/debug/ieee80211/phy0/ath9k/debug
#set the interrupt delay in driver
echo $delay > /sys/kernel/debug/ieee80211/phy0/ath9k/force_quiet_bit_delay
#clean possible history configuration form previous tests
echo 1 > /sys/kernel/debug/ieee80211/phy0/ath9k/force_quiet_bit_restore
echo 0 > /sys/kernel/debug/ieee80211/phy0/ath9k/force_quiet_bit_restore
#tell driver to printk output after processing [count] packets
echo $packet_num > /sys/kernel/debug/ieee80211/phy0/ath9k/max_timing_count
#use packet injector to send [count] packets
/root/packetspammer -c $packet_num mon0 -d0
#wait for possible delays in executing printk
sleep 1
#print kernel debug information, where the test result will be put
dmesg -c
#clear the interrupt delay we set in the driver (0 means disable interrupt)
echo 0 > /sys/kernel/debug/ieee80211/phy0/ath9k/force_quiet_bit_delay
