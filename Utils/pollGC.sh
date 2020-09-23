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

# Record the %RAW USED and pending GC count
get_rawUsed
get_pendingGC
updatelog "%RAW USED ${rawUsed}; Pending GCs ${pendingGC}" $log

# wait till cluster reaches '$threshold' fill mark
while (( $(awk 'BEGIN {print ("'$rawUsed'" < "'$threshold'")}') )); do
    # RGW system Load Average
    echo -n "LA: " | tee -a $log        # prefix line with stats label
    get_upTime
    updatelog "${RGWhostname} ${upTime}" $log

    # RGW radosgw PROCESS and MEM stats
    echo -n "RGW: " | tee -a $log        # prefix line with stats label
    get_rgwMem
    updatelog "${RGWhostname} ${rgwMem}" $log

    # ceph-osd PROCESS and MEM stats
    echo -n "OSD: " | tee -a $log        # prefix line with stats label
    get_osdMem
    updatelog "${RGWhostname} ${osdMem}" $log

    # Sleep for the poll interval
    sleep "${interval}"
    # Record the %RAW USED and pending GC count
    get_rawUsed
    get_pendingGC
    updatelog "%RAW USED ${rawUsed}; Pending GCs ${pendingGC}" $log
done

updatelog "** ${threshold}% fill mark hit: POLLGC ending" $log

#echo " " | mail -s "POLLGC fill mark hit - terminated" user@company.net
