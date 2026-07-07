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
declare -a MOUNTED_ROOTS=()
declare -a MOUNTED_PARTS=()

cleanup() {
  sync || true
  umount "$MNT_A" 2>/dev/null || true
  umount "$MNT_B" 2>/dev/null || true
  rmdir "$MNT_A" "$MNT_B" 2>/dev/null || true
}
trap cleanup EXIT

mount_rootfs() {
  part="$1"
  mnt="$2"
  name="$3"

  if [ ! -b "$part" ]; then
    echo "Skipping $name ($part): block device does not exist" >&2
    return 0
  fi

  fstype="$(lsblk -no FSTYPE "$part" | head -n 1 | tr -d "[:space:]" || true)"
  if [ -z "$fstype" ]; then
    echo "Skipping $name ($part): no filesystem detected" >&2
    return 0
  fi

  if ! mount "$part" "$mnt"; then
    echo "Failed to mount $name ($part, fstype=$fstype)" >&2
    echo "Check dmesg for the kernel mount error." >&2
    exit 1
  fi

  MOUNTED_ROOTS+=("$mnt")
  MOUNTED_PARTS+=("$part")
}

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

mount_rootfs "$ROOT_A" "$MNT_A" "rootfs_a"
mount_rootfs "$ROOT_B" "$MNT_B" "rootfs_b"

if [ "${#MOUNTED_ROOTS[@]}" -eq 0 ]; then
  echo "No mountable rootfs partitions found on $DEV" >&2
  exit 1
fi

for i in "${!MOUNTED_ROOTS[@]}"; do
  inject_rootfs "${MOUNTED_ROOTS[$i]}"
done

echo "Injected static eth0 IP service into: ${MOUNTED_PARTS[*]}"
EOF
