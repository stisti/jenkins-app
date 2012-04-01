#!/bin/bash
timeout=$(($(date +%s) + 60))
while [ $(date +%s) -lt $timeout ] && ! curl -sfk "$1" >/dev/null; do
    logger -t Jenkins.app "Jenkins is not responding yet, sleeping..."
    sleep 1
done
logger -t Jenkins.app "Not waiting any longer"
curl -sfk "$1" >/dev/null
