![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/dariogriffo/spotifast-debian/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/dariogriffo/spotifast-debian/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/spotifast-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/spotifast-debian)

<h1>
   <p align="center">
     <a href="https://spotifast.rocks/"><img src="https://github.com/dariogriffo/spotifast-debian/blob/main/spotifast-logo.png" alt="spotifast Logo" width="128" style="margin-right: 20px"></a>
     <a href="https://www.debian.org/"><img src="https://github.com/dariogriffo/spotifast-debian/blob/main/debian-logo.png" alt="Debian Logo" width="104" style="margin-left: 20px"></a>
     <br>spotifast for Debian
   </p>
</h1>
<p align="center">
 Spotify, native and fast.
</p>

# spotifast for Debian

This repository contains build scripts to produce the _unofficial_ Debian packages
(.deb) for [spotifast](https://github.com/crmne/spotifast/) hosted at [deb.griffo.io](https://deb.griffo.io)

Currently supported Debian distros are:
- Trixie (v13)
- Forky (v14)
- Sid (testing)

Currently supported Ubuntu distros are:
- Noble (24.04)
- Questing (25.10)
- Resolute (26.04)

Supported architectures:
- amd64 (x86_64)
- arm64 (aarch64)

Upstream publishes no armhf, i386, riscv64 or ppc64el binaries, so those
architectures are not available. The binaries upstream ships are glibc linked
and built on Ubuntu 24.04, so they need `libc6 (>= 2.39)`; that is why Bookworm
(glibc 2.36) and Jammy (glibc 2.35) are not supported.

The package installs the `spotifast` binary, the desktop entry and the
application icon, so it shows up in the application menu.

`fonts-noto-cjk` and `fonts-noto-core` are recommended: titles in Chinese,
Japanese, Korean, Arabic, Hebrew, Thai and Indic scripts are drawn with fonts
found on the system, and without them they render as boxes.

Local playback requires a Spotify Premium account.

This is an unofficial community project to provide a package that's easy to
install on Debian. If you're looking for the spotifast source code, see
[spotifast](https://github.com/crmne/spotifast/).

## Install/Update

📖 **Step-by-step install guide:** [Debian](https://deb.griffo.io/install-latest-spotifast-in-debian.html) · [Ubuntu](https://deb.griffo.io/install-latest-spotifast-in-ubuntu.html)

### The Debian way

> ⚠️ **apt access requires a yearly subscription**
> ([deb.griffo.io](https://deb.griffo.io)). To use this tool for free, download
> the .deb from the [Releases](https://github.com/dariogriffo/spotifast-debian/releases) page
> and install it manually (see below).

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list
sudo apt update
sudo apt install -y spotifast
```

### Manual Installation

1. Download the .deb package for your Debian version available on
   the [Releases](https://github.com/dariogriffo/spotifast-debian/releases) page.
2. Install the downloaded .deb package.

```sh
sudo dpkg -i <filename>.deb
```

## Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

## Building

### Build for single architecture
```sh
./build.sh <spotifast_version> <build_version> <architecture>
# Example: ./build.sh 0.2.0 1 arm64
```

### Build for all architectures
```sh
./build.sh <spotifast_version> <build_version> all
# Example: ./build.sh 0.2.0 1 all
```

## Disclaimer

- This repo is not open for issues related to spotifast. This repo is only for _unofficial_ Debian packaging.
- spotifast is an independent project and is not affiliated with Spotify. Spotify is a trademark of Spotify AB.
