#!/bin/bash

if [ -z $1 ]; then
  echo "Usage: $0 interval [number of lines]"
  exit 1
else
  INTERVAL=$1
fi

NUM_LINES=10
[ $2 ] && NUM_LINES=$2

calc_lines() {
  if [ $NUM_LINES -gt 0 ]; then
    ACTIVE_LINES=$(($CPU/$NUM_LINES))
    LINES=""
    for (( i = 0; i < $NUM_LINES; i++ )); do
      if [[ $i < $ACTIVE_LINES ]]; then
        LINES="$LINES|"
      else
        LINES="$LINES "
      fi
    done
  fi
}

if [[ $OSTYPE =~ darwin* ]]; then
  # OS X
  cpu_info=$(iostat -n0 -c${INTERVAL} | tail -n1)
  CPU=$(echo $cpu_info | cut -d' ' -f1)
  LOAD=$(echo $cpu_info | cut -d' ' -f4-6)

  mem_info=($(vm_stat))
  WIRED="${mem_info[24]%?}"
  ACTIVE="${mem_info[14]%?}"
  INACTIVE="${mem_info[17]%?}"
  FREE="${mem_info[11]%?}"

  TOTAL_MEM=$(( ($WIRED + $ACTIVE + $INACTIVE + $FREE) * 4096 / 1024 / 1024 ))
  FREE_MEM=$(( ($INACTIVE + $FREE) * 4096 / 1024 / 1024 ))
  USED_MEM=$(( ($WIRED + $ACTIVE) * 4096 / 1024 / 1024 ))
elif [[ $OSTYPE =~ linux* ]]; then
  # Linux
  CPU=$(vmstat 1 ${INTERVAL} | tail -n1 | awk '{print $13}')
  LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg)

  mem_info=($(free -m))
  TOTAL_MEM=${mem_info[7]}
  USED_MEM=${mem_info[15]}
fi

if [ $NUM_LINES -gt 0 ]; then
  calc_lines
  echo "$(hostname) | ${USED_MEM}/${TOTAL_MEM}MB | [${LINES}] CPU: ${CPU}% | $(date '+%Y-%m-%d %H:%M')"
else
  echo "$(hostname) | ${USED_MEM}/${TOTAL_MEM}MB | CPU: ${CPU}% | $(date '+%Y-%m-%d %H:%M')"
fi