# One canonical WSL candidate set

Updated 2026-10-25. The user selected WSL as the only final-artifact storage location. Use `/mnt/android-build/artifacts/x605f-final`, inside the existing native build VHDX; do not maintain additional final-package copies on Windows drives or the remote development machine.

| File | Purpose | SHA-256 prefix |
| --- | --- | --- |
| `boot.img` | Existing ReSukiSU/SAR boot candidate | `e660527cb325` |
| `recovery.img` | Downloaded X605F TWRP 3.7.0_9 | `266873bedbbd` |
| `system.img` | Current EvoX system candidate | `f6be0e18cb1a` |
| `vendor.img` | Current repaired vendor candidate | `4ab3e6a3dd1c` |
| `system-6g-option.img` | Distinct optional 6 GiB system layout input | `1864d5dbd63d` |
| `ReSukiSU-manager-arm64.apk` | Matching root manager | `2deccb3ac73f` |
| `ksud` | Matching root userspace tool | `9a4344ef76b7` |

The optional 6 GiB file is a different image, not a second identical copy of `system.img`; no live partition layout has been selected. Never flash both system images as successive required steps.

The native directory contains `manifest.json`, `SHA256SUMS`, and a short README. Verify with `cd /mnt/android-build/artifacts/x605f-final && sha256sum -c SHA256SUMS` before later extraction. A future extraction should create only the needed temporary Windows copy, not a permanent second package.

The recovered boot came from the earlier audit's `repacked.img`. Its full SHA-256 and byte count match the frozen candidate exactly, and its original repack report records zero changed bytes. The initial conclusion that this boot was missing was incorrect; the old filename search did not locate this differently named artifact.

Consolidation verifies all seven hashes before moving files and verifies them again afterward. Images already on the build volume are renamed within that filesystem. TWRP moves from the Ubuntu root filesystem into the canonical set; its previous complete image is removed as part of the move. The redundant historical hardlink name for the optional 6 GiB image is removed after checking inode identity. Source, Git objects, downloads and provenance reports are not removed.

These are completed offline candidates, not a validated flash combination. SELinux exceptions, vendor verity/unlocked handling, live GPT/layout selection and hardware acceptance remain documented device-stage gates. No partition write, bootloader operation or new Android build is performed by consolidation.
