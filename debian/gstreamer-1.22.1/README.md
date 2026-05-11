## 1. Install dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential meson ninja-build git pkg-config libglib2.0-dev \
  flex bison libx11-dev libgl1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev \
  libdrm-dev libgbm-dev libgudev-1.0-dev libx11-xcb-dev libwayland-dev \
  wayland-protocols libgtk-3-dev libfdk-aac-dev libva-dev
```

## 2. Fetch source code

```bash
git clone -b 1.22.1 --depth=1 https://gitlab.freedesktop.org/gstreamer/gstreamer.git
```


## 3. Apply the patch

```bash
cd gstreamer
git apply gstreamer_1_22_1_for_cix_2026q1.patch
```

## 4. Build and install

Place the build script `build.sh` in the `gstreamer` directory.
```bash
./build.sh
```
