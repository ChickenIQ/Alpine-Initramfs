#!/bin/sh -e

OUT_DIR="./out"
SRC_DIR="./src"
BUILD_DIR=$(mktemp -d)

build_variant() {
  variant="$1"
  echo "Running variant script: $SRC_DIR/$variant.sh"
  SCRIPT_CHROOT=yes alpine-make-rootfs "$BUILD_DIR/$variant" "$SRC_DIR/$variant.sh"
  
  # Generate initramfs
  echo "Creating initramfs for $variant"
  (cd "$BUILD_DIR/$variant" && find . -print0 | cpio --null -o -H newc | gzip) > "$OUT_DIR/initramfs-$variant"

  echo "Variant $variant built successfully."
}

# Build base variant
mkdir -p "$BUILD_DIR/base/etc/mkinitfs" "$OUT_DIR"
echo "disable_trigger=yes" > "$BUILD_DIR/base/etc/mkinitfs/mkinitfs.conf"
build_variant "base"

# Move kernel to output directory
mv "$BUILD_DIR/$variant/boot/vmlinuz"* "$OUT_DIR/vmlinuz"
rm -rf "$BUILD_DIR/base/boot"

# Build all other variants
for script in "$SRC_DIR"/*.sh; do
  variant="$(basename "$script" .sh)"
  [ "$variant" != "base" ] && {
    cp -a "$BUILD_DIR/base" "$BUILD_DIR/$variant"
    build_variant "$variant"
  }
done

# Cleanup build directory
rm -rf "$BUILD_DIR"

# Set ownership
chown -R 1000:1000 "$OUT_DIR"

echo "All variants built successfully."