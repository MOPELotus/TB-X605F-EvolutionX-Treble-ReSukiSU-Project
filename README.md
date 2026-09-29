# TB-X605F Evolution X Treble / ReSukiSU

Project notes and repeatable preparation for bringing up an Evolution X Treble GSI on the Lenovo Tab M10 TB-X605F Wi-Fi model.

## Target and direction

- Device: Lenovo Tab M10 TB-X605F Wi-Fi, reported as 3 GB RAM / 32 GB eMMC.
- First bring-up: Evolution X Android 16 QPR2 GApps Treble GSI, stock Lenovo Pie vendor and kernel.
- Later: a reproducible Treble build, a clean self-built Lenovo 3.18.120 kernel, then ReSukiSU Manual Hook, and only then Android 17 work.
- Keep the GApps/Evolution X feature set. Use measured GPT data to decide whether system needs expansion; do not guess sectors.

## Current status

- This repository began as a project plan. Device properties, GPT, backups, and recovery package have not yet been collected here.
- Upstream references and host preparation are being recorded under `docs/`.
- The current Linux workstation is an Ubuntu 24.04 x86_64 development environment. It has 96 logical CPUs and 125 GiB RAM, but only about 39 GiB free on `/home`, so it is not the Android source/build host.
- The Windows build machine is reported by the user to have an Intel Core Ultra 9 275HX, 64 GB DDR5, and at least 400 GB free. Its WSL/Linux-visible memory, storage path, and tools still need a read-only preflight.
- Raw device backups, factory firmware, system images, and logs belong in local artifact storage and must not be committed as ordinary Git blobs.

## Start here

1. Read [the project plan](TB-X605F_EvolutionX_Treble_ReSukiSU_Project_Plan%28%E5%8F%8C%E6%9C%BA%E5%BC%80%E5%8F%91%E7%89%88%29.md).
2. Read [the current upstream baseline](docs/upstream-baseline.md), [Windows/WSL handoff](docs/windows-build-handoff.md), and [recovery package research](docs/recovery-package-research.md).
3. On the Windows machine, run `scripts/windows/inspect-build-host.ps1`; inside WSL, use the `--phase sync` preflight before source checkout. See [the Windows/WSL handoff](docs/windows-build-handoff.md) for commands.
4. Before any device write, use the Windows read-only collection scripts and complete the backup checklist in `docs/partition-layout.md`.

## Safety and evidence

- Treat device state as unknown until read from the actual TB-X605F. The partition table in particular must come from this tablet.
- Keep raw backups, proprietary firmware, and large images outside normal Git history. Commit only source, patches, scripts, metadata, and summarized logs.
- Do not use generic GSI flashing recipes until the actual bootloader, AVB, partition, and recovery behavior is known for this device.
- A successful build or boot animation is not hardware acceptance. Keep the hardware matrix in `docs/test-matrix.md` tied to exact build hashes.
- Graphics acceptance uses the tablet's physical GPU and real screen interactions, as specified in the project plan.
