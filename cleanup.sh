#!/bin/bash
# CLEANUP.sh
# User must create $CFGFILE proir to running this script
# See   "s3cmd --configure -c s3test.cfg"

CFGFILE=./s3test.cfg
# make sure S3 cfg file exists
[ -f "$CFGFILE" ] && echo "continuing" || echo "$CFGFILE does not exist."; exit

# Empty and Remove the buckets 
s3cmd rb s3://mycontainers1 -c s3test.cfg --recursive || {
    echo "Error removing s3://mycontainers1, exit"
    exit 1
}
s3cmd rb s3://mycontainers2 -c s3test.cfg --recursive || {
    echo "Error removing s3://mycontainers2, exit"
    exit 1
}
s3cmd rb s3://mycontainers3 -c s3test.cfg --recursive || {
    echo "Error removing s3://mycontainers3, exit"
    exit 1
}
s3cmd rb s3://mycontainers4 -c s3test.cfg --recursive || {
    echo "Error removing s3://mycontainers4, exit"
    exit 1
}
s3cmd rb s3://mycontainers5 -c s3test.cfg --recursive || {
    echo "Error removing s3://mycontainers5, exit"
    exit 1
}

# Process GCs
radosgw-admin gc process --include-all &
radosgw-admin gc process --include-all &
radosgw-admin gc process --include-all &

# Wait for all GCs to be processed, none PENDING
Utils/completedGC.sh 5m /tmp/hold

# cleanup
rm -f /tmp/hold
