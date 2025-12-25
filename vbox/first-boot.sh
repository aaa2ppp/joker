#!/bin/sh

set -e

: ${VBoxManage:?}
: ${VMName:?}

: ${TMP_DIR:="./tmp"}
: ${SSH_DIR:=".joker/ssh"}
: ${SSH_KEY:="$SSH_DIR/id_ed25519"}

freebsd_timeout=60

echo "Waiting for '$VMName' startup $freebsd_timeout sec..." >&2
sleep $freebsd_timeout

echo "Initial configuration of FreeBSD..."

mkdir -p "$TMP_DIR"
initial_configure="$TMP_DIR/initial_configure.$$"

cat > "$initial_configure" << EOF
root

pw useradd joker -G wheel -m -s /bin/sh -w no
touch ~joker/.hushlogin
mkdir -m 700 ~joker/.ssh
chown joker:joker ~joker/.ssh
echo "$(cat "${SSH_KEY}.pub")" > ~joker/.ssh/authorized_keys
sysrc sshd_enable=YES
service sshd start
exit
EOF

"$VBoxManage" controlvm "$VMName" keyboardputfile "$initial_configure"
rm "$initial_configure"
