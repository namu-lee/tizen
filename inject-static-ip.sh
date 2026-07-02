#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /dev/sdX" >&2
  exit 2
fi

DEV="$1"

sudo bash -s -- "$DEV" <<'EOF'
set -euo pipefail

DEV="$1"

case "$DEV" in
  /dev/sd*|/dev/vd*)
    ROOT_A="${DEV}2"
    ROOT_B="${DEV}12"
    ;;
  /dev/mmcblk*|/dev/nvme*)
    ROOT_A="${DEV}p2"
    ROOT_B="${DEV}p12"
    ;;
  *)
    echo "Unsupported device name: $DEV" >&2
    exit 1
    ;;
esac

sync
partprobe "$DEV" 2>/dev/null || true
sleep 2

MNT_A="$(mktemp -d)"
MNT_B="$(mktemp -d)"

cleanup() {
  sync || true
  umount "$MNT_A" 2>/dev/null || true
  umount "$MNT_B" 2>/dev/null || true
  rmdir "$MNT_A" "$MNT_B" 2>/dev/null || true
}
trap cleanup EXIT

mount "$ROOT_A" "$MNT_A"
mount "$ROOT_B" "$MNT_B"

inject_rootfs() {
  root="$1"

  mkdir -p "$root/usr/local/sbin"
  mkdir -p "$root/etc/systemd/system/multi-user.target.wants"

  cat > "$root/usr/local/sbin/force-eth0-sdb-ip.sh" <<'SCRIPT'
#!/bin/sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin
ADDR=192.168.1.11/24

i=0
while [ "$i" -lt 90 ]; do
    if [ -d /sys/class/net/eth0 ]; then
        if command -v ip >/dev/null 2>&1; then
            ip link set eth0 up 2>/dev/null || true
            ip addr replace "$ADDR" dev eth0 2>/dev/null || true
        elif command -v ifconfig >/dev/null 2>&1; then
            ifconfig eth0 192.168.1.11 netmask 255.255.255.0 up 2>/dev/null || true
        fi
    fi
    i=$((i + 1))
    sleep 2
done

exit 0
SCRIPT

  chmod 0755 "$root/usr/local/sbin/force-eth0-sdb-ip.sh"

  cat > "$root/etc/systemd/system/force-eth0-sdb-ip.service" <<'SERVICE'
[Unit]
Description=Keep eth0 static IP for SDB
After=local-fs.target network-pre.target network.target connman.service systemd-networkd.service
Wants=network.target

[Service]
Type=simple
ExecStart=/usr/local/sbin/force-eth0-sdb-ip.sh
Restart=no

[Install]
WantedBy=multi-user.target
SERVICE

  chmod 0644 "$root/etc/systemd/system/force-eth0-sdb-ip.service"

  ln -sfn /etc/systemd/system/force-eth0-sdb-ip.service \
    "$root/etc/systemd/system/multi-user.target.wants/force-eth0-sdb-ip.service"
}

inject_rootfs "$MNT_A"
inject_rootfs "$MNT_B"

echo "Injected static eth0 IP service into $ROOT_A and $ROOT_B"
EOF
