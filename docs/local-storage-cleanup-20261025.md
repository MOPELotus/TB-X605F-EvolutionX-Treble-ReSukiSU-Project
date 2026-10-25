# Local generated-file cleanup and VHDX compaction — 2026-10-25

The user authorized removing locally regenerable output while retaining source, large downloaded dependencies, toolchains and final candidates. No source synchronization, network download, Git object pruning, distro reinstallation or device write was performed.

## Removed and retained scope

- Removed the old `out.pre-cdrive`, old and current compiler caches, and current Android `out`. Recreated the output/cache directories with the source owner's UID/GID and retained the existing output symlink.
- Removed superseded snapshot images, generated system/APEX extraction trees, ELF projections, linker-configuration fixtures and an experimental minimized image. Kept their small provenance, diagnostic and audit reports.
- Preserved `.repo`, source worktrees and changes, source backups, downloaded prebuilts/toolchains, Gradle downloads, original stock inputs, downloaded root/recovery inputs, and the current system/vendor candidates. Unclassified input directories were not treated as disposable caches.
- Retained the built host tools separately under the build volume's `artifacts/retained-host-tools-20261025`. Checked seven key binaries against their original copies before deleting `out`; the retained `avbtool version` runs successfully afterward.
- The two cleanup execution reports record 56 and 66 allowlisted paths. Each run validates mount identity, quiet build/sync state, deletion boundaries, absence of nested mounts, and protected final image hashes. Private execution reports and DiskPart logs remain local in `.codex-patch-stage` and are not committed.

## Compression and validation

Guest filesystems were synchronized and trimmed, the build filesystem was normally unmounted, and WSL was stopped before Windows DiskPart compacted the detached VHDX files. Both DiskPart logs explicitly report successful compaction. A second C-only pass followed the final generated-projection cleanup.

| Active disk | Before cleanup | After compaction and startup validation |
| --- | ---: | ---: |
| C build VHDX | 313,301,925,888 bytes, 291.79 GiB | 68,287,463,424 bytes, 63.60 GiB |
| E Ubuntu VHDX | 711,711,522,816 bytes, 662.83 GiB | 636,694,298,624 bytes, 592.97 GiB |

Approximately 298 GiB was returned to Windows backing storage. At final inspection, C had about 300 GiB free and E about 227 GiB free; these are observations, not reservations. D was not cleaned by this operation.

Ubuntu startup, source/toolchain paths, output/cache permissions, and the build disk UUID/bind mount passed checks after compaction. The build filesystem contains about 23 GiB of retained data; the larger VHDX file length reflects residual allocated filesystem/VHD blocks, not another hidden source checkout.

The following SHA-256 values passed before cleanup, after cleanup, and again after final compaction:

- System: `f6be0e18cb1ad3196efb52609e0bfbbbd0298763f8dbf683c6df24d61feebc2b`.
- Optional 6 GiB derivative: `1864d5dbd63d2246311d14f23b3dc62dab796cf921b92da7880e79af0cd63e85`.
- Current vendor candidate: `4ab3e6a3dd1c14fe77c3f0b343dedda5cb26b721a91c165dec41ca684418e02a`.
- Downloaded TWRP: `266873bedbbd925f083fe05997d8531342c47e79704a304f3330e55320e176f7`.

## Existing delivery gap

Before deletion began, the old E-volume firmware-research/final-delivery directory was already absent. The initial search missed a differently named audit artifact, `full-stack-audit-20261002/boot-repack-consistency-20261003/repacked.img`. Its size is 29,990,912 bytes and its actual SHA-256 is `e660527cb3253e705f21a5daf97e62268b8f696a5402c3f844964900d9ade811`, exactly the previously frozen ReSukiSU/SAR boot. The original repack report also records byte equality and zero changed bytes. The boot was not deleted and does not need recompilation merely because the old E delivery directory is absent. Initial missing-boot observations and local cleanup reports are superseded by this verified discovery.

The user subsequently selected one WSL-only canonical candidate set, documented in `wsl-final-artifacts.md`. Complete images are moved, not copied to multiple Windows drives. Historical reports retain their original input paths; the canonical manifest records their new locations. This is still offline candidate preparation, not hardware or flash acceptance.

Rebuilding Android now requires a full local compilation instead of an incremental build. Downloaded source/dependency caches were retained, but no full post-cleanup Android rebuild was run to establish completely offline reproducibility.
