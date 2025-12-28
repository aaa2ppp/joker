#!/bin/sh

set -e

: ${VBoxManage:?}
: ${VMName:?}

: ${CHECKS:="0 5 10 15 25 40 60"}
: ${OFFSET:=5}

printf "Waiting for '$VMName' to power off: " >&2

start=$(date +%s)
for check_time in $CHECKS; do
    # Ждём до времени проверки
    while [ $(date +%s) -lt $(( start + OFFSET + check_time )) ]; do
        sleep 1
        printf "." >&2
    done
    
    state="$("$VBoxManage" showvminfo "$VMName" --machinereadable)"

    if echo "$state" | grep -q 'VMState="poweroff"'; then 
        echo "POWER OFF" >&2
        exit 0
    fi

    if echo "$state" | grep -q 'VMState="aborted"'; then 
        echo "ERROR: VM ABORTED" >&2
        exit 1
    fi    
done

echo "TIMEOUT" >&2
exit 1
