#!/bin/sh

disk="ada1"

if ! zpool list | grep -q '^workpool'; then
    if [ -e /dev/ada1 ]; then
        echo "Setting up data disk on /dev/$disk..."

        # Уничтожаем возможную старую разметку
        gpart destroy -F $disk 2>/dev/null || true

        # Создаём новый GPT и раздел
        gpart create -s gpt $disk
        gpart add -t freebsd-zfs -l workdisk ${disk}

        # Создаём ZFS-пул
        zpool create -f -o ashift=12 -O mountpoint=/work workpool /dev/${disk}p1

        # Опционально: создаём датасеты
        # zfs create workpool/src
        # zfs create workpool/jails
        # zfs create workpool/logs

        echo "Data pool 'workpool' created at /work"
    else
        echo "WARNING: /disk/${disk} not found — skipping data disk setup"
    fi
else
    echo "Data pool 'workpool' already exists"
fi
