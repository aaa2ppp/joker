#!/bin/sh

set -e

echo "Provisioning on first boot..."

: ${VBoxManage:?}
: ${VMName:?}

tmp_dir=${TMP_DIR:-"./tmp"}
mkdir -p "$tmp_dir"

ssh_dir=${SSH_DIR:-"./.ssh"}
mkdir -p "$ssh_dir"
chmod 0700 "$ssh_dir"

boot_menu_timeout=5
freebsd_timeout=60
sshd_timeout=60

ssh_key="$ssh_dir/id_ed25519"
echo y | ssh-keygen -t ed25519 -f "$ssh_key" -N ""

"$VBoxManage" startvm "$VMName" --type headless

# press enter on boot menu to speed up start freebsd
sleep $boot_menu_timeout
"$VBoxManage" controlvm "$VMName" keyboardputscancode 1c

echo "Waiting for FreeBSD startup $freebsd_timeout sec..."
sleep $freebsd_timeout

echo "Initial configuration of FreeBSD..."
initial_configure="${tmp_dir}/initial_configure.$$"
cat > "$initial_configure" << EOF
root

pw useradd joker -G wheel -m -s /bin/sh -w no
touch ~joker/.hushlogin
mkdir -m 700 ~joker/.ssh
chown joker:joker ~joker/.ssh
echo "$(cat "${ssh_key}.pub")" > ~joker/.ssh/authorized_keys
sysrc sshd_enable=YES
service sshd start
exit
EOF

"$VBoxManage" controlvm "$VMName" keyboardputfile "$initial_configure"
rm "$initial_configure"

timeout=$sshd_timeout
echo -n "Waiting for sshd startup...$timeout"

while true; do
    sleep 2
    timeout=$(( timeout - 2 ))

    if [ $(( timeout % 10 )) -eq 0 ]; then
        echo -n $timeout
    else
        echo -n '.'
    fi
    if [ $timeout -le 0 ]; then
        echo " timeout expired"
        exit 1
    fi

    if ssh-keyscan -t ed25519,rsa -p 2222 127.0.0.1 > "$ssh_dir/known_hosts" 2>/dev/null; then
        ssh-keyscan -t ed25519,rsa -p 2222 localhost >> "$ssh_dir/known_hosts" 2>/dev/null
        echo " done"
        break
    fi
done

sh install-sudo.sh

echo "Provisioning commands sent. VM ready for SSH on port 2222"
echo "Use: sh joker [COMMAND]"
