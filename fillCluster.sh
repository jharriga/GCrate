#!/bin/bash
# FillCLUSTER.sh

myPath="${BASH_SOURCE%/*}"
if [[ ! -d "$myPath" ]]; then
    myPath="$PWD" 
fi

# Variables
source "$myPath/vars.shinc"

# Functions
source "$myPath/Utils/functions.shinc"

# Create log file - named in vars.shinc
if [ ! -d $RESULTSDIR ]; then
  mkdir -p $RESULTSDIR || \
    error_exit "$LINENO: Unable to create RESULTSDIR."
fi
touch $LOGFILE || error_exit "$LINENO: Unable to create LOGFILE."
updatelog "${PROGNAME} - Created logfile: $LOGFILE" $LOGFILE

# Record STARTING cluster capacity
var1=`echo; ceph df | head -n 5`
var2=`echo; ceph df | grep rgw.buckets.data`
updatelog "$var1$var2" $LOGFILE
# Record the %RAW USED and pending GC count
get_rawUsed
get_pendingGC
updatelog "%RAW USED ${rawUsed}; Pending GCs ${pendingGC}" $LOGFILE

# Run the COSbench workload to fill the cluster
updatelog "START: cosbench launched" $LOGFILE
./Utils/cos.sh ${myPath}/${FILLxml} $LOGFILE

# Record ENDING cluster capacity and GC stats
var1=`echo; ceph df | head -n 5`
var2=`echo; ceph df | grep rgw.buckets.data`
updatelog "$var1$var2" $LOGFILE
# Record the %RAW USED and pending GC count
get_rawUsed
get_pendingGC
updatelog "%RAW USED ${rawUsed}; Pending GCs ${pendingGC}" $LOGFILE

updatelog "$PROGNAME: Done" $LOGFILE

# DONE
