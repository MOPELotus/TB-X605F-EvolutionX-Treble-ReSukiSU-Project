# Known issues and hypotheses

Every item here is a lead to verify, not a confirmed defect on this particular tablet.

## Historical X605F SAR workaround

The 2022 `modify_phh_gsi_sar` project reports that a GSI attempting an online `/system` remount/resize can abort init and remain at the Lenovo logo on affected X605F/L/X705F/L devices. Its approach included offline fsck/resize in recovery, mounting the system block device at `/system_root`, binding `/system_root/system` to `/system`, and disabling the GSI's online remount/resize path.

Before adapting it, inspect the current Android 16 Treble init scripts and current recovery's SAR behavior. Keep any retained workaround conditional and scoped to a proven failure with logs. Do not run the old script unchanged.

## Legacy vendor compatibility

- Expected vendor generation from the project baseline: Android 9 / VNDK 28 / VNDK Lite. This must be verified from the device.
- HWC, GPU composition, hardware video codecs, Wi-Fi, suspend/resume, and wake reliability are first-priority risks because the tablet is intended for second-screen and video use.
- The upstream GSI's generic flashing notes mention dynamic partitions; they do not establish this tablet's actual GPT or bootloader support.
- The upstream product's GApps label and `PICO` flag require package-set inspection; see `upstream-baseline.md`.
