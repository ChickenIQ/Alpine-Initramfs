#/bin/sh -e

# Install required packages
apk add --no-cache sgdisk dosfstools e2fsprogs

# Remove Persistence Setup
rm -f /etc/init.d/setup-persistence
rc-update del setup-persistence sysinit

# Create Format script
cat << 'EOF' > /usr/bin/alpine-format
#!/bin/sh -e
dev="$1"

if [ ! -b "${dev}" ]; then
  echo "Device ${dev} does not exist."
  exit 1
fi

sgdisk -Z \
  -n 1::+1M -t 1:ef02 -c 1:"alpine-bios" \
  -n 2::+5G -t 2:ef00 -c 2:"alpine-boot" \
  -n 3::    -t 3:8300 -c 3:"alpine-data" \
  "${dev}"

# Handle nvme vs sd device naming
part="${dev}"
[[ "$dev" == *"nvme"* ]] && part="${dev}p"

mkfs.fat -F 32 -I "${part}2"
mkfs.ext4 -F "${part}3"

mount "${part}2" /boot
mount "${part}3" /data
alpine-update-boot
EOF

chmod +x /usr/bin/alpine-format
