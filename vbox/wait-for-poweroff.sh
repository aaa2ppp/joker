#!/bin/sh

set -e

: ${VBoxManage:?}
: ${VMName:?}

timeout=${1:-60}

printf "Waiting for '$VMName' to power off: " >&2

while [ $timeout -gt 0 ]; do
    sleep 2
    timeout=$(( timeout - 2 ))

    state="$("$VBoxManage" showvminfo "$VMName" --machinereadable)"

    if echo "$state" | grep -q 'VMState="poweroff"'; then 
        echo "POWER OFF" >&2
        exit 0
    fi

    if echo "$state" | grep -q 'VMState="aborted"'; then 
        echo "ERROR: VM ABORTED" >&2
        exit 1
    fi    

    if [ $(( timeout % 10 )) -eq 0 ]; then
        printf "$timeout" >&2
    else
        printf "." >&2
    fi
done

echo "TIMEOUT" >&2
exit 1
