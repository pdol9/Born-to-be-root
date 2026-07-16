#!/bin/bash

set -e

ARCH=$(uname -a)
CPU=$(cat /proc/cpuinfo | grep "physical id" | sort | uniq | wc -l)
VCPU=$(cat /proc/cpuinfo | grep "^processor" | wc -l)
RAM_USED=$(free -h | grep Mem | awk '{print $3}')
RAM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
RAM_PERC=$(free -k | grep Mem | awk '{printf("%.2f%%"), $3 / $2 * 100}')
DISK_USED=$(df -h --total | grep total | awk '{print $3}')
DISK_TOTAL=$(df -h --total | grep total | awk '{print $2}')
DISK_PERC=$(df -h --total | grep total | awk '{print $5}')
LOAD=$(top -bn1 | grep '^%Cpu' | xargs | awk '{printf("%.1f%%"), $2 + $4}')
BOOT=$(who -b | awk '{print $3,$4}')
LVM=$(if [ $(lsblk | grep lvm | wc -l) -eq 0 ]; then echo no; else echo yes; fi)
TCP=$(cat /proc/net/tcp | wc -l | awk '{print $1-1}' | tr '\n' ' ' && echo "ESTABLISHED")
USER_LOG=$(who | wc -l)
IP=$(hostname -I | awk '{print $1}')
MAC=$(ip link show | grep link/ether | awk '{print $2}')
SUDO_LOG=$(grep COMMAND /var/log/sudo/sudo.log | wc -l)

wall "
		-------------------------------------------------------------
	
		Architecture	: $ARCH
		Physical CPU	: $CPU
		Virtual CPU		: $VCPU
		Memory Usage    : $RAM_USED/$RAM_TOTAL ($RAM_PERC)
		Disk Usage      : $DISK_USED/$DISK_TOTAL ($DISK_PERC)
		CPU load		: $LOAD
		Last boot		: $BOOT
		LVM use			: $LVM
		TCP	Connections : $TCP
		User log		: $USER_LOG
		Network			: IP $IP ($MAC)
		Sudo            : $SUDO_LOG commands used
	
		-------------------------------------------------------------
	"
