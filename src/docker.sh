#/bin/sh -e

# Install docker package
apk add --no-cache docker

# Enable docker service
rc-update add docker default

# Allow docker to run from initramfs
echo 'export DOCKER_RAMDISK=true' >> /etc/conf.d/docker