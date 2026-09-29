# SynapShare open-source components

SynapShare is a proprietary application. Its packages also ship open-source
programs and libraries whose licenses require the corresponding source to be
available. This repository is where that source lives:

- the **patches** SynapShare applies to them (`patches/`),
- the **build definitions** used to compile them (`flatpak/`),
- for every SynapShare release, the **complete source archives** of the exact
  revisions it ships, attached to the GitHub release tagged
  `synapshare-v<version>`.

SynapShare itself does not link against Deskflow: it runs `deskflow-core` as
a separate program and talks to it only through command-line arguments,
configuration files and its log output.

## Components

| Component | License | Modified | Where SynapShare ships it |
|---|---|---|---|
| [Deskflow](https://github.com/deskflow/deskflow) (`deskflow-core`) | GPL-2.0-only WITH LicenseRef-OpenSSL-Exception | Linux Flatpak only - `patches/deskflow/` | All desktop packages |
| [libportal](https://github.com/flatpak/libportal) | LGPL-3.0-only | Yes - `patches/libportal/` | Linux Flatpak |
| [libei](https://gitlab.freedesktop.org/libinput/libei) | MIT | No | Linux Flatpak |

The Windows and macOS packages bundle Deskflow's **official, unmodified**
release binaries. Their Deskflow commit is listed per release in
[VERSIONS.md](VERSIONS.md), and its source archive is attached to that
release. Libraries bundled inside those official binaries (for example Qt and
OpenSSL) are Deskflow's upstream dependencies, as built by the Deskflow
project; see Deskflow's own release notes for their versions.

License texts are in [LICENSES/](LICENSES/).

## Building

The Linux build definitions are flatpak-builder module files. SynapShare's
Flatpak manifest includes them as

```yaml
modules:
  - path/to/synapshare-oss/flatpak/python3-jinja2.yml
  - path/to/synapshare-oss/flatpak/libei.yml
  - path/to/synapshare-oss/flatpak/libportal.yml
  - path/to/synapshare-oss/flatpak/gtest.yml
  - path/to/synapshare-oss/flatpak/deskflow-core.yml
```

on the `org.kde.Sdk` / `org.kde.Platform` 6.10 runtime. To build Deskflow the
same way outside Flatpak, check out the commit in `flatpak/deskflow-core.yml`,
apply `patches/deskflow/*.patch` with `git apply`, and configure with the
CMake options listed in that file.

To replace the Deskflow that an installed SynapShare uses, build it as above
and put the resulting `deskflow-core` where the package keeps it
(`/app/bin` in the Flatpak, the `deskflow/` folder next to the executable on
Windows, `SynapShare.app/Contents/Resources/deskflow/` on macOS).

## Making a release

```sh
scripts/make_source_release.sh 0.3.0 [<deskflow commit of Windows/macOS binaries> ...]
git tag synapshare-v0.3.0
gh release create synapshare-v0.3.0 dist/0.3.0/*
```

then add the release's row to [VERSIONS.md](VERSIONS.md).
