#!/bin/bash
#
# POLLGC.sh
#   Polls ceph and logs stats for GC stats
#

# Bring in other script files
myPath="${BASH_SOURCE%/*}"
if [[ ! -d "$myPath" ]]; then
    myPath="$PWD"
fi

# Variables
source "$myPath/../vars.shinc"

# Functions
source "$myPath/../Utils/functions.shinc"

# check for passed arguments
[ $# -ne 2 ] && error_exit "POLLGC.sh failed - wrong number of args"
[ -z "$1" ] && error_exit "POLLGC.sh failed - empty first arg"
[ -z "$2" ] && error_exit "POLLGC.sh failed - empty second arg"

interval=$1          # how long to sleep between polling
log=$2               # the logfile to write to
DATE='date +%Y/%m/%d:%H:%M:%S'
threshold="85.0"     # percent fill before exit - ceph df

# update log file with ceph %RAW USED 
updatelog "** POLLGC started with threshold = ${threshold}%" $log

case $cephver in
luminous)
  rawUsed=`ceph df | head -n 3 | tail -n 1 | awk '{print $4}'`
  ;;
nautilus)
  rawUsed=`ceph df | head -n 3 | tail -n 1 | awk '{print $10}'`
  ;;
*)
  updatelog "unable to gather %RAW USED stats, exit..." $log
  exit
  ;;
esac  
pendingGC=`radosgw-admin gc list --include-all | wc -l`
updatelog "%RAW USED ${rawUsed}; Pending GCs ${pendingGC}" $log

# wait till cluster reaches '$threshold' fill mark
while (( $(awk 'BEGIN {print ("'$rawUsed'" < "'$threshold'")}') )); do
    sleep "${interval}"
    # Record the %RAW USED and pending GC count
    rawUsed=`ceph df | head -n 3 | tail -n 1 | awk '{print $4}'`
    case $cephver in
    luminous)
      rawUsed=`ceph df | head -n 3 | tail -n 1 | awk '{print $4}'`
      ;;
    nautilus)
      rawUsed=`ceph df | head -n 3 | tail -n 1 | awk '{print $10}'`
      ;;
    *)
      updatelog "unable to gather %RAW USED stats, exit..." $log
      exit
      ;;
    esac
    pendingGC=`radosgw-admin gc list --include-all | wc -l`
    updatelog "%RAW USED ${rawUsed}; Pending GCs ${pendingGC}" $log
done

updatelog "** ${threshold}% fill mark hit: POLLGC ending" $log

#echo " " | mail -s "POLLGC fill mark hit - terminated" user@company.net
