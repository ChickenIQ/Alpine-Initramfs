#/bin/sh -e

# Install required packages
apk add --no-cache sgdisk dosfstools e2fsprogs

# Remove Persistence Setup
rm -f /etc/init.d/setup-persistence
rc-update del setup-persistence sysinit

# Alpine Disk Formatter
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

mkdir -p /boot /data
mount "${part}2" /boot
mount "${part}3" /data
EOF

chmod +x /usr/bin/alpine-format

# Alpine Installer
cat << 'EOF' > /usr/bin/alpine-install
#!/bin/sh -e
image=$(sed -n 's/.*alpine\.image="\?\([^" ]*\)"\?.*/\1/p' /proc/cmdline)
if [ -z "${image}" ]; then
  echo "alpine.image not specified in kernel cmdline"
  exit 1
fi

disk=$(sed -n 's/.*alpine\.installdisk="\?\([^" ]*\)"\?.*/\1/p' /proc/cmdline)
if [ -z "${disk}" ]; then
  echo "alpine.installdisk not specified in kernel cmdline"
  exit 1
fi

alpine-format "${disk}"
alpine-limine-update
alpine-limine-config "alpine.image=${image}" "1"

alpine-image-update ${image} 
EOF

chmod +x /usr/bin/alpine-install

# Installer Service
cat << 'EOF' > /etc/init.d/installer
#!/sbin/openrc-run
description="Run Alpine Installer"
depend() {
  need localmount net
  after dhcpcd
}

start() {
  slot=$(/usr/bin/alpine-current-slot)
  if [ "$slot" = "installer" ]; then
    ebegin "Running Alpine Installer"
    alpine-install
    eend $?
    reboot
  fi
}
EOF

chmod +x /etc/init.d/installer
rc-update add installer default