#!/bin/sh

set -e

: ${VBoxManage:?}
: ${VMName:?}

timeout=${1:-60}

echo -n "Waiting for VM '$VMName' to power off..."

while "$VBoxManage" showvminfo "$VMName" --machinereadable 2>/dev/null | grep -q 'VMState="running\|paused\|stopping"'; do
    if [ $(( timeout % 5 )) -eq 0 ]; then
        echo -n "$timeout"
    else
        echo -n "."
    fi
    if [ $timeout -le 0 ]; then
        echo " timeout expired"
        exit 1
    fi
    sleep 2
    timeout=$(( timeout - 2 ))
done

echo " poweroff"
