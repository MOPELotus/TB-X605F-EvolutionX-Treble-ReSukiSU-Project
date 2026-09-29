# Hardware working matrix

No matrix items have been tested on the target device yet. Every result must name the exact system/boot build ID and hash, vendor baseline, date, steps, observed result, and relevant logs/screenshots.

| Area | Checks | Result | Build ID / SHA-256 | Evidence |
|---|---|---|---|---|
| Boot | cold boot, animation, SetupWizard, ADB, reboot | not tested | | |
| Display | SurfaceFlinger, HWC, GPU, rotation, brightness, screen off/on | not tested | | |
| Touch | multi-touch, edge input, rotation | not tested | | |
| Network | Wi-Fi association, throughput, sustained second-screen transfer | not tested | | |
| Media | H.264/H.265 hardware decode where supported, long playback | not tested | | |
| Audio | speakers, microphone, 3.5 mm output, Bluetooth audio | not tested | | |
| Other hardware | Bluetooth, cameras, sensors, USB, MTP | not tested | | |
| Power | charging, battery reporting, suspend/resume, deep sleep | not tested | | |
| Stability | several-hour second-screen and video sessions, no random reboot | not tested | | |

For graphics acceptance, verify renderer/device logs identify the tablet's physical GPU and inspect screenshots after interacting with the actual UI. A boot result or process exit code alone is insufficient.
