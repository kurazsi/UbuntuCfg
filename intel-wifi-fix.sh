#!/bin/sh

# For Ubuntu 18.04 file should be copied to /etc/init.d/ and set following properties: 
# -rwxr-xr-x 1 root root      intel-wifi-fix.sh

# configuration variables:
TOTAL_ALLOWED_RUNS=5
TIME_BETWEEN_REMOVE_COMMANDS=5s
TIME_BETWEEN_ADDING_COMMANDS=5s
TIME_AFTER_ADDING_BEFORE_CHECKING_IF_WIFI_WORKS=10s
readonly TOTAL_ALLOWED_RUNS

# internal used variables:
CURRENT_RUN=0
TOTAL_RUNS=0

CONDITION=`( iwconfig 2>&1 ) | grep -Po '^((?!\S+\s+no wireless extensions)\S*)'`

if [ ! -z $CONDITION ]; then
  echo "====>$(date) INTEL WIFI FIX EXECUTED, WIFI ALREADY ENABLED... exiting"  >> /var/log/intel-wifi-fix.log
  exit 0
fi

#repeate until wifi available
while [ false ]
do
  echo "Removing kernel modules iwl4965,iwl3945 and iwlwifi..."
  # first remove all the wifi kernel drivers
  (modprobe iwl4965 -r 2>&1) > /dev/null
  (modprobe iwl3945 -r 2>&1) > /dev/null
  (modprobe iwlwifi -r 2>&1) > /dev/null

  sleep $TIME_BETWEEN_REMOVE_COMMANDS
  echo "    kernel modules removed."

  if [ $CURRENT_RUN -eq 0 ]; then
      CURRENT_RUN=1
      # Now try to add and repeat if it fails
      echo "Adding kernel module iwl4965"
      modprobe iwl4965
      sleep $TIME_BETWEEN_REMOVE_COMMANDS
      echo "Adding kernel module iwl3945"
      modprobe iwl3945
      # This needs to be added last.
      sleep $TIME_BETWEEN_REMOVE_COMMANDS
      echo "Adding kernel module iwlwifi"
      modprobe iwlwifi
  else
      CURRENT_RUN=0
      # Now try to add and repeat if it fails
      echo "Adding kernel module iwl3945"
      modprobe iwl3945
      sleep $TIME_BETWEEN_ADDING_COMMANDS
      echo "Adding kernel module iwl4965"
      modprobe iwl4965
      # This needs to be added last.
      sleep $TIME_BETWEEN_ADDING_COMMANDS
      echo "Adding kernel module iwlwifi"
      modprobe iwlwifi
  fi

  echo "Wait $TIME_AFTER_ADDING_BEFORE_CHECKING_IF_WIFI_WORKS and then check if wifi adapter is available"
  sleep $TIME_AFTER_ADDING_BEFORE_CHECKING_IF_WIFI_WORKS

  if [ ! -z $CONDITION ]; then
    echo "====>$(date) INTEL WIFI FIX EXECUTED, WIFI ENABLED SUCCESSFULLY !"  >> /var/log/intel-wifi-fix.log
    break
  else
    if [ $TOTAL_RUNS -eq $TOTAL_ALLOWED_RUNS ]; then
       echo "==ERROR:==>$(date) INTEL WIFI FIX EXECUTED, SCRIPT FAILED !!! CRITICAL ERROR , requires manual investigation !!!!!!" >> /var/log/intel-wifi-fix.log
       exit -1
    fi
    TOTAL_RUNS=`expr $TOTAL_RUNS + 1`
    echo $CONDITION
    echo "FAILED RETRYING..."
  fi
done

