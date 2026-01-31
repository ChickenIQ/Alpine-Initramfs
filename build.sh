#!/bin/sh -e

OUT_DIR="./out"
SRC_DIR="./src"
BUILD_DIR=$(mktemp -d)

build_variant() {
  variant="$1"
  if [ -d "$SRC_DIR/files/$variant" ]; then
    echo "Copying files for variant $variant"
    cp -a "$SRC_DIR/files/$variant/." "$BUILD_DIR/$variant/"
  fi

  echo "Running variant script: $SRC_DIR/scripts/$variant.sh"
  SCRIPT_CHROOT=yes alpine-make-rootfs "$BUILD_DIR/$variant" "$SRC_DIR/scripts/$variant.sh"
  
  # Generate initramfs
  echo "Creating initramfs for $variant"
  (cd "$BUILD_DIR/$variant" && find . -print0 | cpio --null -o -H newc | gzip) > "$OUT_DIR/initramfs-$variant"

  echo "Variant $variant built successfully."
}

# Build base variant
mkdir -p "$OUT_DIR"
build_variant "base"
mv "$BUILD_DIR/$variant/boot/vmlinuz"* "$OUT_DIR/vmlinuz"
rm -rf "$BUILD_DIR/base/boot"

# Build all other variants
for script in "$SRC_DIR"/scripts/*.sh; do
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