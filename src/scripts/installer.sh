#/bin/sh -e

# Install required packages
apk add --no-cache sgdisk dosfstools e2fsprogs

# Setup Installer Service
rc-update add installer default

# Remove Persistence Setup
rm -f /etc/init.d/setup-persistence
rc-update del setup-persistence sysinit