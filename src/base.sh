#!/bin/sh
set -e

# Install base packages
apk add --no-cache alpine-base linux-firmware-none linux-lts util-linux openssh dhcpcd limine oras-cli

# Default services
rc-update add hwdrivers sysinit
rc-update add devfs sysinit
rc-update add dmesg sysinit
rc-update add mdev sysinit

rc-update add networking boot
rc-update add bootmisc boot
rc-update add hostname boot
rc-update add hwclock boot
rc-update add seedrng boot
rc-update add modules boot
rc-update add sysctl boot 
rc-update add syslog boot
rc-update add swap boot

rc-update add killprocs shutdown
rc-update add savecache shutdown
rc-update add mount-ro shutdown

rc-update add acpid default
rc-update add crond default
rc-update add sshd default

# Additional services
rc-update add ntpd default
rc-update add dhcpcd boot

# Configure syslog to limit log size and discard logs
echo 'SYSLOGD_OPTS="-C5120 -O /dev/null"' > /etc/conf.d/syslog

# Prevent networking service from failing due to missing configuration
touch /etc/network/interfaces

# Set default root password to 'alpine'
echo "root:alpine" | chpasswd

# Setup hostname and remove motd
echo "alpine" > /etc/hostname
rm /etc/motd

# Add init symlink
ln -s /sbin/init /init

# Add default Limine config
cat << 'EOF' > /usr/share/limine/limine.conf
${CMDLINE}=""

default_entry: 1
timeout: 5

/Alpine (A)
  protocol: linux
  path: boot():/vmlinuz-A
  cmdline: ${CMDLINE} alpine.slot=A 
  module_path: boot():/initramfs-A

/Alpine (B)
  protocol: linux
  path: boot():/vmlinuz-B
  cmdline: ${CMDLINE} alpine.slot=B
  module_path: boot():/initramfs-B
EOF

# Create init script to mount optional Alpine partitions
cat << 'EOF' > /etc/init.d/setup-persistence
#!/sbin/openrc-run

description="Mount optional Alpine boot and data partitions"

depend() {
  need dev
  after mdev
  before localmount
}

start() {
  ebegin "Mounting Persistence Partitions"

  if [ -e "/dev/disk/by-partlabel/alpine-boot" ]; then
    [ ! -d "/boot" ] && mkdir -p /boot  
    mount -o defaults,noatime /dev/disk/by-partlabel/alpine-boot /boot
    einfo "Mounted alpine-boot on /boot"
  fi

  if [ -e "/dev/disk/by-partlabel/alpine-data" ]; then
    [ ! -d "/data" ] && mkdir -p /data
    mount -o defaults,noatime /dev/disk/by-partlabel/alpine-data /data
    einfo "Mounted alpine-data on /data"
  fi

  eend 0
}

stop() {
  ebegin "Unmounting Persistence Partitions"
  umount /data 2>/dev/null
  umount /boot 2>/dev/null
  eend 0
}
EOF

mkdir -p /boot /data
chmod +x /etc/init.d/setup-persistence
rc-update add setup-persistence sysinit

cat << 'EOF' > /usr/bin/alpine-update-boot
#!/bin/sh -e
dev=$(findmnt -n -o SOURCE /boot | sed 's/p\?[0-9]*$//')
if [ -z "${dev}" ]; then
  echo "/boot is not mounted"
  exit 1
fi

# Install Default Config  
mkdir -p /boot/limine
if [ ! -f /boot/limine.conf ]; then
  cp /usr/share/limine/limine.conf /boot/limine
fi

# EFI Boot
mkdir -p /boot/EFI/BOOT/
cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/

# BIOS Boot
limine bios-install "${dev}"
cp /usr/share/limine/limine-bios.sys /boot/limine
EOF

chmod +x /usr/bin/alpine-update-boot

# Install SSH keys
mkdir -p /root/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJF4Waz2pv+NAEsLMT1kaFbtYjx6faBRPgHzlHdN30In" >> /root/.ssh/authorized_keys
