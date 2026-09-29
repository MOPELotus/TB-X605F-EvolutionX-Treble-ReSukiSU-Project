# Stock recovery package research

Checked: 2026-09-29. No stock QFIL/9008 archive has been downloaded or validated yet.

## Official route

Lenovo's [Rescue and Smart Assistant page for Tab M10 / Smart Tab M10 (TB-X605F, TB-X605L)](https://pcsupport.lenovo.com/us/en/products/tablets/m-series-tablets/tab-m10/downloads/ds101291-rescue-and-smart-assistant-lmsa) lists the Windows rescue utility. Use it on the Windows machine to query the exact connected model and save the firmware package it offers. The listing verifies the rescue utility is available for the product family; it does not prove that a specific Android 9 ROW package remains available from the service.

## Community leads

- [HalabTech's TB-X605F index](https://support.halabtech.com/index.php?a=downloads&b=folder&id=46946) lists `TB-X605F_S000033_20191204_Q00020_ROW_Factory_Rescue.zip` (listed as 1.00 GB) and a `USERDEBUG` rescue variant. The listing is model-specific, but the download endpoint returned HTTP 403 from this Linux workstation. No package contents, checksum, or accessibility have been verified.
- [Lolinet's TB-X605F firmware directory](https://mirrors-obs-2.lolinet.com/firmware/lenowow/2019/Tab_M10/TB-X605F/) exposes ROW archives for `S210175`, `S210208`, `S210224`, and `S210273`, plus `Q00332` packages. These are separate/newer candidates; do not assume they are the same Android 9 factory-rescue package.
- Lenovo's [open-source-code page](https://support.lenovo.com/in/en/downloads/ds544614-open-source-code-tab-m10-smart-tab-m10-tablet-tb-x605f-tb-x605l) lists a kernel source archive. It is source code, not a flashable QFIL rescue package.

## Acceptance for a recovery archive

Before treating any candidate as the project restore package, confirm the exact TB-X605F Wi-Fi target, Android/ROW build, archive integrity, and presence of the correct Qualcomm firehose programmer, rawprogram XML, patch XML, and required images. Save the original archive, compute SHA-256, list the archive contents, and keep both the archive and extracted working copy outside normal Git history. A filename or a firmware web listing alone is not enough.
