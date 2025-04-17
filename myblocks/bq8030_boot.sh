#!/bin/bash

#DEBUG="2>/dev/null"

if [[ `lsmod | grep i2c_dev` = "" ]]; then
  sudo modprobe i2c-dev
  echo "Load module i2c-dev"
fi

if [[ $1 = "" ]]; then
  for (( i=1; i < `ls /sys/class/i2c-adapter/ | wc -l`; i++ ))
  do
    if [ "`cat /sys/class/i2c-adapter/i2c-$i/name | grep 2112`" != "" ]; then DEV="--device=i2c:///dev/i2c-$i"; fi
  done
else
  DEV=$1
fi
echo "DEV=$DEV"
SMBUSBCOM="sudo smbusb_comm"

echo "---Start---"
echo ""

write_initial=$($SMBUSBCOM $DEV -a 16 -c 71 -w 0214 2>/dev/null)
echo "--- write 71: 0214 ---"
sleep 0.2
if [[ ! -z "$write_initial" ]]; then
    echo "Lost communication when initializing register 71"
    exit 1
fi

read_73=$($SMBUSBCOM $DEV -a 16 -c 73 -r 2 2>/dev/null)
echo "--- read 73: $read_73 ---"
sleep 0.2
    if [[ -z "$read_73" ]]; then
        echo "Lost communication with chip r73"
        exit 1
    fi

w71=$((0x10000-0x$read_73))
wr71=$(printf "%04x" $w71)
write_71=$($SMBUSBCOM $DEV -a 16 -c 71 -w $wr71 2>/dev/null)
echo "--- write 71: $wr71  ---"
sleep 0.2
    if [[ ! -z "$write_71" ]]; then
        echo "Lost communication with chip w71"
        exit 1
    fi

write_70=$($SMBUSBCOM $DEV -a 16 -c 70 -w 0517 2>/dev/null)
echo ""
    if [[ -z "$write_70" ]]; then
        echo "!!!-----------------BOOTMODE ACCESS-----------------!!!"
    else
        echo "Lost communication with chip w70"
        exit 1
    fi
