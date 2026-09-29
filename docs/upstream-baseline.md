# Upstream baseline

Checked: 2026-09-29. These are discovery snapshots, not immutable build locks. Record a `repo manifest -r` from the actual synced Windows/WSL source tree before building.

## First-stage GSI candidate

- Project: [Doze-off/EvoX_treble](https://github.com/Doze-off/EvoX_treble)
- Manifest branch: `16.2`
- Manifest repository commit observed: `a53b47e521a21c0c5f0aa4765ac20a69403d40a8`
- Latest release observed: [2026-09-20](https://github.com/Doze-off/EvoX_treble/releases/tag/2026-09-20), labelled `Evolution X 11.11 | A16 QPR2 | TREBLE GSI UNOFFICIAL-signed`.
- GApps/architecture asset: `EvoX-11.11-GSI_treble_arm64-ab-GAPPS-20260920.img.xz` (1,537,972,692 bytes on the release API).
- Downloaded to `/home/lotus/TB-X605F-artifacts/evox-gsi-2026-09-20/` on the Linux workstation. Compressed SHA-256: `a538369f62d3f7779a7c9b1cc503f9dc776b50ef114d8e77a87afd96088e70a3`; raw image SHA-256: `5e8333e15798592bae059bcb78ba85394418afc8f035a13fc0e97c086b8c1e49`. The release byte count matched and the XZ CRC64 stream check passed. The raw image is an ext4 filesystem, 3,863,474,176 bytes long; its superblock reports 4,096-byte blocks and a 3,802,427,392-byte filesystem. It is not an Android sparse image.
- Read-only inspection of the prebuilt image found core GMS/Play components, but no Chrome or Google Photos APK directories. The current upstream product selects PICO GApps, so this image is not the project's full-GApps build target.
- This is an unofficial community Treble build, not an Evolution X official device build. It is a candidate for first-stage compatibility work, subject to package inspection and device fit.
- The branch manifest pins AOSP to `android-16.0.0_r2` and includes Evolution X projects from `bka`; it does not by itself prove the final image is reproducible or that every custom Treble patch is represented.
- The upstream README includes generic fastboot commands for dynamic-partition devices. Those commands are not a TB-X605F flashing procedure. Do not apply them to this tablet without its measured GPT and recovery/bootloader evidence.

## GApps package selection

The current [Doze-off device tree](https://github.com/Doze-off/device_phh_treble-doze/blob/android-16.0/evox_gsi.mk) defines `WITH_GMS := true` and `TARGET_USES_PICO_GAPPS := true`. Its product inherits `vendor/lineage/config/common_full_phone.mk`; that file selects `vendor/gms/gms_pico.mk` when the PICO flag is true, and otherwise selects `vendor/gms/gms_full.mk`. The upstream GApps image is therefore a reduced PICO package set and does not satisfy this project's full-GApps requirement.

`patches/treble/0001-evox-gsi-use-full-gapps.patch` clears the MINI/PICO flags for the custom `evox_gsi` target so Evolution X's common product selects `gms_full.mk`, and installs the built Treble settings APK. The local manifest pins `vendor_gms` from the current Evolution-X GitHub mirror because the Doze-off 16.2 snippet still points to its former Codeberg host. Keep the full package set; grow system to fit after reading the tablet's actual GPT.

## Treble device tree

- Project: [Doze-off/device_phh_treble-doze](https://github.com/Doze-off/device_phh_treble-doze)
- Branch observed: `android-16.0`, pushed 2026-09-24.
- Commit pinned in `manifests/x605f-evox-a16.xml`: `6a740bfe0ecd6b23de598f64bbd00b66c3bef29c`.
- Its `AndroidProducts.mk` contains an `evox_gsi` product, and `evox_gsi.mk` targets `tdgsi_arm64_ab` with GMS enabled.
- The branch needs to be captured at an exact commit and its upstream patch/build dependencies audited before treating it as a reproducible build recipe.

The local manifest also pins Evolution `vendor_gms` (`89c3940a77298c204c55a21efded92ddafb59fe9`), the matching Doze-off hardware overlay (`7d6d1bde72ccbc370a936565e6c7def45a2294ca`), TrebleDroid vendor interfaces (`a2271d260e226e8de5cb1e8c15a229dc90c007dd`), and AOSP VNDK 28/29 prebuilts (`1cb210981d2baf325aaab36cdd84afa40c775f00` / `2e659f04a7cde964415c82dd7507610769165408`). `treble_app` is included from its `master` branch and will be pinned in the full `repo manifest -r` after sync.

## Kernel and SAR references

- Lenovo source: [Yahoo-Mike/android_kernel_lenovo_X605F](https://github.com/Yahoo-Mike/android_kernel_lenovo_X605F), branch `official-3.18.120`, observed commit `71070ded2014ecbb12c9fdb173522657f3dc931d`.
- Its README identifies the TB-X605F/L msm-3.18.120 source and documents an arm64 build using `m10_msmcortex_defconfig` and an Android GCC 4.9 cross compiler. The host's GCC 13 / Clang 18 is not a replacement for that legacy Android toolchain.
- Historical SAR reference: [modify_phh_gsi_sar](https://github.com/sophiel-meow/modify_phh_gsi_sar). Use it as a documented failure/fix reference. Compare its behavior against the current Android 16 Treble init and current recovery before adapting anything.
- ReSukiSU manual integration: [official guide](https://resukisu.org/guide/manual-integrate). Do not integrate it until a clean self-built kernel is proven on the device; inspect current hook signatures against the checked-out 3.18 source at that later stage.

## Build-host requirements

- The [AOSP host requirements](https://source.android.com/docs/setup/start/requirements) currently specify at least 400 GB free for checkout plus build output and at least 64 GB RAM. The page currently describes `android17-release`; the Windows machine's 64 GB physical RAM is at the stated minimum, so check what WSL2 actually exposes before sync/build.
- Microsoft documents WSL2's default memory cap as 50% of Windows memory and recommends keeping Linux command-line work in the WSL filesystem for fastest performance: [WSL configuration](https://learn.microsoft.com/windows/wsl/wsl-config), [working across filesystems](https://learn.microsoft.com/windows/wsl/filesystems).
