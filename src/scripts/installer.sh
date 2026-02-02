#/bin/sh -e

# Install required packages
apk add --no-cache sgdisk dosfstools e2fsprogs

# Setup Installer Service
rc-update add alpine-installer default

# Remove Persistence Setup
rm -f /etc/init.d/alpine-persistence
rc-update del alpine-persistence sysinit