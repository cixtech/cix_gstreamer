#!/usr/bin/env bash
set -euo pipefail

PREFIX=/usr/share/cix
STAGE_INSTALL_DIR=/tmp/cix-gstreamer-native-install

CIX_INC=/usr/share/cix/include
export CFLAGS="${CFLAGS:-} -I$CIX_INC"
export CXXFLAGS="${CXXFLAGS:-} -I$CIX_INC"
export CPPFLAGS="${CPPFLAGS:-} -I$CIX_INC"

# setup build env and compile code
rm -rf build
meson setup --prefix="$PREFIX" --libdir=lib --strip -Dauto_features=disabled --wrap-mode=nodownload \
  -Dbase=enabled -Dgood=enabled -Dbad=enabled \
  -Dgst-plugins-base:gl=enabled -Dgst-plugins-base:x11=enabled \
  -Dgst-plugins-good:v4l2=enabled -Dgst-plugins-good:gtk3=enabled \
  -Dgst-plugins-bad:kms=enabled -Dgst-plugins-bad:fdkaac=enabled -Dgst-plugins-bad:va=enabled \
  build
ninja -C build

# install lib to stage dir
rm -rf "$STAGE_INSTALL_DIR"
mkdir -p "$STAGE_INSTALL_DIR"
DESTDIR="$STAGE_INSTALL_DIR" meson install -C build

# copy lib to /usr
from_lib="$STAGE_INSTALL_DIR$PREFIX/lib"
from_plugins="$from_lib/gstreamer-1.0"

sudo install -d "$PREFIX/lib/gstreamer-1.0" "$PREFIX"
shopt -s nullglob
for p in libgstvideo-1.0.so* libgstgl-1.0.so*; do
  sudo cp -a "$from_libs/$p" "$PREFIX/lib/"
done
for p in libgstafbcparse.so libgstcixsr.so libgstcoreelements.so libgstfdkaac.so libgstgtk.so \
  libgstkms.so libgstopengl.so libgstvideo4linux2.so libgstva.so; do
  sudo cp -a "$from_plugins/$p" "$PREFIX/lib/gstreamer-1.0/"
done
shopt -u nullglob
