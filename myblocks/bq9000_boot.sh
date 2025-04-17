#!/bin/bash

if [[ $1 = "" ]]; then
  for (( i=1; i < `ls /sys/class/i2c-adapter/ | wc -l`; i++ ))
  do
    if [ "`cat /sys/class/i2c-adapter/i2c-$i/name | grep 2112`" != "" ]; then DEV="--device=i2c:///dev/i2c-$i"; fi
  done
else
  DEV=$1
fi

if [ -f /tmp/i2c-dev ]; then
DEV="--device=i2c://"`cat /tmp/i2c-dev`
fi
echo "DEV="$DEV
SMBUSBCOM="sudo smbusb_comm"

if [[ `lsmod | grep i2c_dev` = "" ]]; then
  sudo modprobe i2c_dev
  echo "Load module i2c_dev"
fi

start=$(date)

# Write 0x0214 to register 71
write_initial=$($SMBUSBCOM $DEV -a 17 -c 71 -w 0214)

echo "write_initial="$write_initial

if [[ ! -z "$write_initial" ]]; then
    echo "Lost communication when initializing register 71"
    exit 1
fi

# Read value from register 74
read_74=$($SMBUSBCOM $DEV -a 17 -c 74 -r 2 2>/dev/null)

i=0
while true; do
    hex=$(printf "%04x" $i)

    read_73=$($SMBUSBCOM $DEV -a 17 -c 73 -r 2 2>/dev/null)

    write_71=$($SMBUSBCOM $DEV -a 17 -c 71 -w $hex 2>/dev/null)
    if [[ ! -z "$write_71" ]]; then
        echo "Lost communication with chip"
        break
    fi

    write_70=$($SMBUSBCOM $DEV -a 17 -c 70 -w 0517 2>/dev/null)

    echo "register 74: $read_74, challenge 73: $read_73, guess: $hex, write_70: $write_70, write_71: $write_71"

    if [[ -z "$write_70" ]]; then
        echo "!!!-----------------BOOTMODE ACCESS-----------------!!!"
        break
    fi

    i=$(( RANDOM % 65536 ))
done

end=$(date)
echo "Started: $start"
echo "Finished: $end"
