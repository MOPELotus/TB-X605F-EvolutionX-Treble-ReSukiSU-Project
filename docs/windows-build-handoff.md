# Windows build-machine handoff

The user reports an Intel Core Ultra 9 275HX, 64 GB DDR5, and at least 400 GB free on the Windows machine. That meets the stated host minimum on paper; the actual WSL filesystem and Linux-visible memory still need a read-only preflight.

## Build environment

Use WSL2 Ubuntu (or a native Linux install) for Android source sync and compilation. Keep the source checkout and `out/` on the distro's Linux filesystem, not under `/mnt/c` or another DrvFs mount. If the large Windows volume is not where the WSL distro's VHDX lives, place/import the distro there before syncing Android sources.

The current AOSP setup guide states 400 GB free and 64 GB host RAM as minimums. WSL2's documented default memory limit is 50% of Windows memory, which would expose about 32 GB on a 64 GB host unless configured. Check `/proc/meminfo` inside WSL; Windows Task Manager's total RAM is not the build environment's available RAM. A practical starting WSL cap is 56 GB, with Windows memory-heavy applications closed during the build and `BUILD_JOBS=16`; watch Windows and Linux memory pressure.

If WSL needs a higher memory cap, edit `%UserProfile%\.wslconfig` on Windows:

```ini
[wsl2]
memory=56GB
processors=24
swap=16GB
```

Apply the change with `wsl --shutdown`, then start the distro again. Confirm the WSL distro's virtual disk is stored on a volume with at least 400 GB free; a separate Windows drive having space does not increase the free space reported for the distro's Linux filesystem.

## Read-only host inspection

From elevated or normal PowerShell, run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
./scripts/windows/inspect-build-host.ps1
```

Then, inside the WSL2 distro and the intended source filesystem:

```bash
mkdir -p "$HOME/android/evox16"
./scripts/preflight-android-build.sh --phase sync "$HOME/android/evox16"
```

Install the host packages and Android `repo` launcher using the [official AOSP setup instructions](https://source.android.com/docs/setup/start/requirements). Also install `git-lfs`, `xz-utils`, and `openjdk-17-jdk` for the pinned manifest and TrebleApp build:

```bash
sudo apt-get update
sudo apt-get install repo git-lfs xz-utils openjdk-17-jdk git-core gnupg flex bison build-essential zip curl zlib1g-dev libc6-dev-i386 x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig
```

The preflight is read-only: it checks disk, Linux-visible memory, filesystem location, Java 17, and required tools but does not install packages or change WSL settings.

## Source baseline

First bring-up is based on the Doze-off EvoX Treble `16.2` manifest and its Android 16 AOSP base, then the exact dependencies in `manifests/x605f-evox-a16.xml`. The helper `scripts/sync-evox-a16-source.sh "$HOME/android/evox16"` initializes an empty source directory or checks a matching existing workspace, installs the local manifest, syncs without force-overwriting, applies the full-GApps/TrebleApp product patch, and records a full `repo manifest -r` lock. It runs the read-only host preflight before source sync.

The upstream `evox_gsi.mk` selects PICO GApps. The local manifest replaces the moved GMS mirror and `scripts/sync-evox-a16-source.sh` applies a tracked patch that selects the full Evolution X GApps set. Preserve that patch and confirm the resolved package list before building. Keep X605F-specific changes in this repository's `patches/`, `overlays/`, and `props/` directories and apply them as explicit, reviewable steps.

## Build sequence

1. Complete the Windows and WSL/Linux host inspections.
2. Run `scripts/sync-evox-a16-source.sh "$HOME/android/evox16"`; it runs the sync preflight and requires at least 400 GB free on the chosen Linux filesystem.
3. Review the generated manifest lock and source sync metadata.
4. Review the resolved manifest, full-GApps product flag, and `evox_gsi-userdebug` product.
5. Confirm at least 150 GB remains free after source checkout, then run `BUILD_JOBS=16 scripts/build-evox-a16-full-gapps.sh "$HOME/android/evox16"`; it builds TrebleApp, builds `systemimage`, and saves the image/hash/manifest/diff metadata outside ordinary Git history.
6. Apply X605F Treble/SAR compatibility changes individually and rebuild with new metadata.
7. Use the Windows side for device survey, backups, flashing, logs, and physical hardware acceptance.

Do not run generic dynamic-partition flashing commands from the upstream GSI README on the TB-X605F. The actual GPT, slot state, AVB state, recovery behavior, and backup set must be recorded first.
