# Partition layout and backup record

No live TB-X605F GPT data has been captured in this repository. Do not calculate or write new sector positions from this template.

## Required per-partition record

| Name | Start LBA | End LBA | Sectors | Bytes | Type GUID | Unique GUID | Filesystem | Backup path | SHA-256 | Restorable check |
|---|---:|---:|---:|---:|---|---|---|---|---|---|
| | | | | | | | | | | |

Save both primary and backup GPT, raw partition metadata, a human-readable table, and the mapping under `/dev/block/by-name`. Record the exact device transport and model before reading. Store raw captures outside Git.

## Device-specific data to retain

At minimum preserve `persist` and every small/unknown NV or calibration partition actually present, including any of `fsg`, `fsc`, `modemst1`, `modemst2`, `sec`, `devinfo`, and `frp`. Do not infer that Wi-Fi-only means these partitions are absent or irrelevant. If storage permits, make a full eMMC raw dump before any GPT change.

## Gate before GPT or system writes

- Device identity is confirmed as TB-X605F.
- Stock ROW QFIL/9008 package is saved, package contents are checked, and SHA-256 is recorded.
- Primary and backup GPT plus all device-specific small partitions are saved and size/hash checked.
- Full raw dump is saved when feasible.
- The current GPT, `system` / `userdata` adjacency, filesystem type, alignment, and actual candidate GSI raw size are measured.
- A restore path is available and recorded.
