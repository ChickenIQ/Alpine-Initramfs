#!/bin/sh
set -e

# Install base packages
apk add --no-cache alpine-base linux-firmware-none linux-lts util-linux dropbear openssh-sftp-server dhcpcd limine oras-cli yq vim

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

# Additional services
rc-update add ntpd default
rc-update add dhcpcd default
rc-update add dropbear default

# Set root password
echo "root:alpine" | chpasswd

# Remove MOTD
rm /etc/motd

# Add init symlink
ln -s /sbin/init /init

# Enable persistence service
rc-update add alpine-persistence sysinit

# Install SSH keys
mkdir -p /root/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJF4Waz2pv+NAEsLMT1kaFbtYjx6faBRPgHzlHdN30In" >> /root/.ssh/authorized_keys
