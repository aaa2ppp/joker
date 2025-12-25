#!/bin/sh

# Простой waiter для sshd
# Работает везде, где есть sh и ssh
# Минимальный риск бана

set -e

: ${REMOTE_HOST:="127.0.0.1"}
: ${REMOTE_PORT:=2222}

: ${CHECKS:="0 5 10 15 25 40 60"}
: ${OFFSET:=0}

printf "Waiting for SSH at ${REMOTE_HOST}:${REMOTE_PORT}: " >&2

start=$(date +%s)
for check_time in $CHECKS; do
    # Ждём до времени проверки
    while [ $(date +%s) -lt $(( start + OFFSET + check_time )) ]; do
        sleep 1
        printf "." >&2
    done
    
    if host_keys=$(ssh-keyscan -p "$REMOTE_PORT" -T 3 "$REMOTE_HOST" 2>/dev/null) && [ -n "$host_keys" ]; then
        echo "READY" >&2
        echo "$host_keys"
        exit 0
    fi
    printf "." >&2
done

echo "TIMEOUT" >&2
exit 1
