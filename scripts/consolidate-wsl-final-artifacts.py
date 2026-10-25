import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess


BUILD = Path('/mnt/android-build')
ARTIFACTS = BUILD / 'artifacts'
AUDIT = ARTIFACTS / 'full-stack-audit-20261002'
SNAPSHOT = ARTIFACTS / 'evox-a16-x605f-bp4a-auditfix-isolation-v2-20261003'
DESTINATION = ARTIFACTS / 'x605f-final'
ENTRIES = (
    ('boot.img', AUDIT / 'boot-repack-consistency-20261003/repacked.img', 'e660527cb3253e705f21a5daf97e62268b8f696a5402c3f844964900d9ade811'),
    ('recovery.img', Path('/home/lotus/TB-X605F-artifacts/recovery/twrp-official-X605F/twrp-3.7.0_9-0-X605F.img'), '266873bedbbd925f083fe05997d8531342c47e79704a304f3330e55320e176f7'),
    ('system.img', SNAPSHOT / 'system.img', 'f6be0e18cb1ad3196efb52609e0bfbbbd0298763f8dbf683c6df24d61feebc2b'),
    ('vendor.img', AUDIT / 'vendor-usb-hci-appcompat-image-isolation-v1-20261003-v2/vendor-usb-hci-appcompat-candidate.img', '4ab3e6a3dd1c14fe77c3f0b343dedda5cb26b721a91c165dec41ca684418e02a'),
    ('system-6g-option.img', SNAPSHOT / 'six-gib-option/system-partition-6g-avb.img', '1864d5dbd63d2246311d14f23b3dc62dab796cf921b92da7880e79af0cd63e85'),
    ('ReSukiSU-manager-arm64.apk', AUDIT / 'root-manager-inputs-20261003/upstream-tools/Manager-release/ReSukiSU_v4.2.0-rc3_35193-arm64-v8a-release.apk', '2deccb3ac73f4ae6a41541b74312f4299bd8e9226d3bf5a1450b922a703ee9d1'),
    ('ksud', AUDIT / 'root-manager-inputs-20261003/upstream-tools/ksud-aarch64-linux-android/aarch64-linux-android/release/ksud', '9a4344ef76b71f4fcc23359fb4d48d59076b2764bd8c3a493ff8d08d8589ca47'),
)


def digest(path):
    checksum = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(16 * 1024 * 1024), b''):
            checksum.update(block)
    return checksum.hexdigest()


def regular_file(path):
    if path.resolve() != path or path.is_symlink() or not path.is_file():
        raise RuntimeError(f'Unexpected artifact path: {path}')


def main():
    parser = argparse.ArgumentParser(description='Move verified final candidates into one native WSL directory.')
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    observed = subprocess.check_output(['findmnt', '-n', '-o', 'UUID', '--mountpoint', str(BUILD)], text=True).strip()
    if observed != '3ea5abae-6dcc-4f98-9707-e43e14cc3893' or DESTINATION.resolve() != DESTINATION:
        raise RuntimeError('Unexpected storage destination')
    verified = []
    for name, source, expected in ENTRIES:
        target = DESTINATION / name
        current = target if target.exists() else source
        regular_file(current)
        if digest(current) != expected:
            raise RuntimeError(f'Artifact hash mismatch: {current}')
        if target.exists() and source.exists():
            raise RuntimeError(f'Two copies exist; review manually: {source} and {target}')
        verified.append({'name': name, 'bytes': current.stat().st_size, 'sha256': expected, 'previous_location': str(source)})
    print(json.dumps({'verified_files': len(verified), 'apply': args.apply, 'destination': str(DESTINATION)}), flush=True)
    if not args.apply:
        return
    DESTINATION.mkdir(exist_ok=True)
    owner = Path('/home/lotus/android/evox16').stat()
    os.chown(DESTINATION, owner.st_uid, owner.st_gid)
    for name, source, expected in ENTRIES:
        target = DESTINATION / name
        if source.exists():
            regular_file(source)
            shutil.move(str(source), str(target))
        if digest(target) != expected:
            raise RuntimeError(f'Post-move hash mismatch: {target}')
    alias = SNAPSHOT / 'six-gib-option/system.img'
    if alias.exists():
        regular_file(alias)
        if not os.path.samefile(alias, DESTINATION / 'system-6g-option.img'):
            raise RuntimeError('Unexpected 6 GiB alias; left untouched')
        alias.unlink()
    manifest = {
        'scope': 'One canonical WSL-only set of existing offline candidates; no device write or new Android build.',
        'boot_recovered_from_byte_identical_audit_repack': True,
        'ready_to_flash': False,
        'hardware_acceptance': False,
        'files': verified,
        'limits': ['Live GPT/layout selection pending.', 'SELinux/verity and real hardware gates remain.', 'The 6 GiB image is an optional layout input, not a selected flash plan.'],
    }
    (DESTINATION / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (DESTINATION / 'SHA256SUMS').write_text(''.join(f"{entry['sha256']}  {entry['name']}\n" for entry in verified))
    (DESTINATION / 'README.txt').write_text(
        'Canonical offline candidates: boot.img (ReSukiSU/SAR), recovery.img (downloaded X605F TWRP), '
        'system.img (EvoX), vendor.img (conditional repaired vendor).\n'
        'system-6g-option.img is optional; do not flash both system images.\n'
        'No hardware acceptance, live layout selection or one-click flashing is implied.\n'
        'Before later extraction: cd to this directory and run sha256sum -c SHA256SUMS.\n'
        'Historical reports retain their original input paths; manifest.json records the moved files.\n'
    )
    print('Canonical set ready; original complete-image paths no longer contain duplicate files.', flush=True)


if __name__ == '__main__':
    main()
