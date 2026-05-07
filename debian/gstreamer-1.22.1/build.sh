#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVOC_DIR="$(pwd)"
cd "$ROOT"

PREFIX=/usr/share/cix
STAGE="${STAGE:-$ROOT/native-install-stage}"
GST_PKG_VER="${GST_PKG_VER:-1.22.1}"
ARCH="$(dpkg --print-architecture)"
DEB_FILE="$INVOC_DIR/cix-gstreamer_${GST_PKG_VER}_${ARCH}.deb"

export CFLAGS="${CFLAGS:-} -I$PREFIX/include"
export CXXFLAGS="${CXXFLAGS:-} -I$PREFIX/include"
export CPPFLAGS="${CPPFLAGS:-} -I$PREFIX/include"

rm -rf build
meson setup --prefix="$PREFIX" --libdir=lib --strip -Dauto_features=disabled --wrap-mode=nodownload \
  -Dbase=enabled -Dgood=enabled -Dbad=enabled \
  -Dgst-plugins-base:gl=enabled -Dgst-plugins-base:x11=enabled \
  -Dgst-plugins-base:videoconvertscale=enabled \
  -Dgst-plugins-good:v4l2=enabled -Dgst-plugins-good:gtk3=enabled \
  -Dgst-plugins-good:deinterlace=enabled \
  -Dgst-plugins-bad:kms=enabled -Dgst-plugins-bad:fdkaac=enabled -Dgst-plugins-bad:va=enabled \
  build
ninja -C build

rm -rf "$STAGE"
mkdir -p "$STAGE"
DESTDIR="$STAGE" meson install -C build

stage_lib="$STAGE$PREFIX/lib"
plug_dir="$stage_lib/gstreamer-1.0"

PKGDIR="$(mktemp -d)"
trap 'rm -rf "$PKGDIR"' EXIT
mkdir -p "$PKGDIR/DEBIAN" "$PKGDIR$PREFIX/lib/gstreamer-1.0"

cat >"$PKGDIR/DEBIAN/control" <<EOF
Package: cix-gstreamer
Version: $GST_PKG_VER
Architecture: $ARCH
Maintainer: Cix OS team
Depends: gstreamer1.0-plugins-good, gstreamer1.0-plugins-bad
Section: utils
Priority: optional
Description: cix-gstreamer package
EOF

shopt -s nullglob
for p in "$stage_lib"/libgstvideo-1.0.so* "$stage_lib"/libgstgl-1.0.so*; do
  cp -a "$p" "$PKGDIR$PREFIX/lib/"
done
shopt -u nullglob

plugins=(
  libgstafbcparse.so libgstcixsr.so libgstcoreelements.so libgstfdkaac.so libgstgtk.so
  libgstkms.so libgstopengl.so libgstvideo4linux2.so libgstva.so libgstdeinterlace.so
  libgstvideoconvertscale.so
)
for p in "${plugins[@]}"; do
  cp -a "$plug_dir/$p" "$PKGDIR$PREFIX/lib/gstreamer-1.0/"
done

dpkg-deb --root-owner-group -Zxz -b "$PKGDIR" "$DEB_FILE"

echo "Built: $DEB_FILE"
sudo dpkg -i "$DEB_FILE"
