# Folimeld Development Guide

[日本語](DEVELOPMENT.md) | [English](DEVELOPMENT_en.md)

This document explains how to set up a development environment, run tests, build the application, and create release packages.

## Technology stack

- Python 3
- PySide6 / Qt Widgets
- PyMuPDF
- Pillow (icon generation)
- PyInstaller (executable generation)
- pytest (testing)

## Development environment setup

### Windows

The Windows edition supports both Intel/AMD (x64) and ARM (ARM64).

```bat
py -m venv .venv
.venv\Scripts\python -m pip install -r requirements-dev.txt
```

### macOS

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements-dev.txt
```

### Ubuntu

Ubuntu 22.04 or later is assumed.

```bash
sudo apt update
sudo apt install python3-venv libegl1 libgl1 libxkbcommon-x11-0 libxcb-cursor0 libxcb-icccm4 libxcb-keysyms1 libxcb-shape0 fonts-noto-cjk
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements-dev.txt
```

`fonts-noto-cjk` is used to display Japanese, Chinese, and Korean text.

## Running from source

Windows:

```bat
.venv\Scripts\python main.py
```

macOS / Ubuntu:

```bash
. .venv/bin/activate
python main.py
```

## Tests

```bash
python -m pytest -q
```

To use the virtual environment directly on Windows:

```bat
.venv\Scripts\python -m pytest -q
```

## Version management

The application's display version is managed by `__version__` in `folimeld/__init__.py`, and the App Store build number by `__build__`. Update either the display version or the build number for every new App Store submission. In particular, increment the build number when resubmitting the same display version.

Version information for the Windows executable is generated at build time by `tools/write_version_info.py`. Ubuntu packages, the macOS App Bundle, and MSIX use the same values.

License documents are bundled through calls to `tools/license_bundle.py` in each spec file.
Review [Licensing and distribution](docs/license-distribution.md) (in Japanese) before distributing the application.

## Icons

Run the following command to generate transparent PNG, ICO, ICNS, and MSIX images from `assets/Folimeld-icon-source.png`.

```bash
python tools/make_app_icon.py
```

Output locations:

- `assets/Folimeld-icon-master.png`
- `assets/Folimeld.iconset/`
- `assets/Folimeld.ico`
- `assets/Folimeld.icns`
- `packaging/msix/Assets/`

## Windows build

```bat
build_exe.bat
```

The output is `dist\Folimeld.exe`, a standalone executable that includes Python, PySide6, PyMuPDF, and translation data.

The unpackaged edition registers Folimeld in Windows **Open with** at startup. The MSIX edition uses file associations in the package manifest instead of registering them in the registry.

## MSIX for Microsoft Store

### Intel/AMD (x64)

```powershell
powershell -ExecutionPolicy Bypass -File .\build_msix.ps1
```

The output is `dist\Folimeld_<バージョン>_x64.msix`, where `<バージョン>` is the version.

For Store submissions, specify the values exactly as shown on the **Product identity** page in Partner Center. These values are case-sensitive. In the examples below, replace the Japanese placeholders with the Package/Identity/Name and Publisher from Partner Center, and the publisher display name.

```powershell
powershell -ExecutionPolicy Bypass -File .\build_msix.ps1 `
  -IdentityName "Partner CenterのPackage/Identity/Name" `
  -Publisher "Partner CenterのPublisher" `
  -PublisherDisplayName "公開者表示名"
```

Omitting these arguments generates an unsigned package with a development identity. To install outside the Store, sign it with a certificate that matches the Publisher in the manifest.

### ARM (ARM64)

Build the ARM64 edition on a physical Windows on ARM device or an ARM64 Windows virtual machine. PyInstaller does not cross-build from x64 to ARM64, so recreate the virtual environment with ARM64 Python and install ARM64-compatible packages for PySide6, PyMuPDF, Pillow, and PyInstaller.

```powershell
powershell -ExecutionPolicy Bypass -File .\build_msix.ps1 -Architecture arm64 `
  -IdentityName "Partner CenterのPackage/Identity/Name" `
  -Publisher "Partner CenterのPublisher" `
  -PublisherDisplayName "公開者表示名"
```

The build script checks the architecture of the Python/PyInstaller environment and stops if it does not match the requested architecture.

## macOS build

```bash
./build_exe.sh
```

The output is `dist/Folimeld.app`. The script creates a virtual environment and installs dependencies as needed.

```bash
open dist/Folimeld.app
```

Ad-hoc signing is used for local verification. For official distribution, sign with an Apple Developer certificate and complete notarization.

### Mac App Store build

In Apple Developer, prepare an App Store application signing certificate, an installer signing certificate, and a provisioning profile with App Sandbox enabled for Bundle ID `com.folimeld.Folimeld`.

Replace the Japanese placeholders below with the Common Names of the application and installer signing certificates, respectively.

```bash
./build_appstore.sh \
  --application-identity "アプリ署名証明書のCommon Name" \
  --installer-identity "インストーラ署名証明書のCommon Name" \
  --provisioning-profile "/path/to/Folimeld.provisionprofile"
```

The output is `dist/Folimeld_<表示バージョン>.pkg`, where `<表示バージョン>` is the display version. The script applies App Sandbox entitlements and signs the application and installer. Before submission, it automatically verifies the application signature, Info.plist, Bundle ID, separation of the display version and build number, PDF document types, Sandbox entitlements, and installer signature. After testing with TestFlight, upload to App Store Connect using Transporter or Xcode.

Update the version in `folimeld/__init__.py` every time you upload to the App Store. The current entitlements do not include network access, as the application only reads and writes PDFs selected by the user through file dialogs.

## Ubuntu build

```bash
bash build_linux.sh
```

The following files are generated (`<バージョン>` means version and `<アーキテクチャ>` means architecture):

- `dist/folimeld`
- `releases/ubuntu/folimeld_<バージョン>_<アーキテクチャ>.deb`

Build distribution deb packages on Ubuntu 22.04 to support Ubuntu 22.04 and later. Building on a newer Ubuntu release may cause the bundled Python or shared libraries to require a newer glibc, preventing the application from starting on 22.04.

```bash
sudo apt install ./releases/ubuntu/folimeld_*.deb
```

The DEB package includes a desktop menu entry, icons, and PDF file associations.

A Linux-specific virtual environment, `.venv-linux`, is used. Set `FOLIMELD_LINUX_VENV` to change its location.
On WSL, using a path on the Linux side (for example, `/tmp/folimeld-build-venv`) speeds up builds.
The minimum `libc6` version for the deb package is determined from the build environment. Packages built on Ubuntu 22.04 target `libc6 >= 2.35`. Always build the executable itself on 22.04; do not merely lower the declared dependency version.

Example of building a distribution deb package from WSL (after installing the required dependencies):

```powershell
wsl -d Ubuntu-22.04 -- bash -lc 'cd /path/to/Folimeld && FOLIMELD_LINUX_VENV=~/.cache/folimeld-build-venv bash build_linux.sh'
```

Adjust the path for your environment. Before distribution, verify deb installation and PDF display, editing, and saving on Ubuntu 22.04, 24.04, and 26.04. When replacing packages, also update `releases/ubuntu/folimeld_<バージョン>_SHA256SUMS.txt`.

The same deb package is distributed for Debian 13 (amd64). Include Debian 13 in testing before distribution. Basic functionality of 0.3.2 has been verified on Debian 13.6 with WSL2 / WSLg (X11). See the [verification record](docs/debian-wsl-verification.md) (in Japanese) for the scope of testing and missing Fontconfig configuration on minimal installations.

### Snap package

After running `build_linux.sh` on Ubuntu 24.04, run:

```bash
sudo snap install snapcraft --classic
bash build_snap.sh
```

The output is `releases/ubuntu/folimeld_<バージョン>_<アーキテクチャ>.snap`.
Snapcraft's default isolated build environment is used. On a dedicated Ubuntu 24.04 build environment or WSL,
you can also build with `sudo bash build_snap.sh --destructive-mode` if installing build dependencies on the host is acceptable.
The package uses `core24` and the GNOME extension, and bundles Qt's X11 libraries, icons, and PDF file associations.

Install and launch the local package:

```bash
sudo snap install --dangerous ./releases/ubuntu/folimeld_0.3.2_amd64.snap
snap run folimeld
```

The Snap runs with strict confinement and can access regular files in the home folder.
To edit PDFs on external drives, run `sudo snap connect folimeld:removable-media`.
Publishing to the Snap Store is a separate procedure from this local build.

## Pre-release checks

1. Update the version in `folimeld/__init__.py`
2. Run all tests
3. Perform a clean build for each target operating system
4. Verify startup, opening files, editing, and saving in an environment without Python installed
5. Verify PDF file associations and uninstallation
6. Verify license and third-party license displays
7. Check MSIX packages with the Windows App Certification Kit

## License

Contributions to this project are provided under the same [GNU Affero General Public License v3.0](LICENSE) terms as the project itself.
