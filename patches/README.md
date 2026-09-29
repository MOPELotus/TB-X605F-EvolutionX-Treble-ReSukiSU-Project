# X605F compatibility patches

Keep one behavior change per patch and classify it under `treble/`, `sar/`, `media/`, `audio/`, `graphics/`, or `init/` as appropriate. Every patch needs a symptom, Android/GSI revision, trigger condition, log evidence, validation steps, and rollback note.

The initial Treble patch switches the upstream EvoX GSI product from PICO to full GApps and packages TrebleApp to preserve the project requirement. This is a build-product policy change, not a device workaround. No hardware compatibility patch is committed because no live X605F failure has been captured. Historical SAR notes are in `docs/known-issues.md`.
