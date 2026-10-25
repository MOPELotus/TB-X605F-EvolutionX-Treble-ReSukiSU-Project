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
SOURCE = Path('/home/lotus/android/evox16')
FINAL = ARTIFACTS / 'evox-a16-x605f-bp4a-auditfix-isolation-v2-20261003'
EXPECTED = {
    FINAL / 'system.img': 'f6be0e18cb1ad3196efb52609e0bfbbbd0298763f8dbf683c6df24d61feebc2b',
    FINAL / 'six-gib-option/system-partition-6g-avb.img': '1864d5dbd63d2246311d14f23b3dc62dab796cf921b92da7880e79af0cd63e85',
    AUDIT / 'vendor-usb-hci-appcompat-image-isolation-v1-20261003-v2/vendor-usb-hci-appcompat-candidate.img': '4ab3e6a3dd1c14fe77c3f0b343dedda5cb26b721a91c165dec41ca684418e02a',
    Path('/home/lotus/TB-X605F-artifacts/recovery/twrp-official-X605F/twrp-3.7.0_9-0-X605F.img'): '266873bedbbd925f083fe05997d8531342c47e79704a304f3330e55320e176f7',
}


def digest(path):
    checksum = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(16 * 1024 * 1024), b''):
            checksum.update(block)
    return checksum.hexdigest()


def ensure_quiet():
    for entry in Path('/proc').iterdir():
        if not entry.name.isdecimal():
            continue
        try:
            command = (entry / 'cmdline').read_bytes().split(b'\0')
        except (FileNotFoundError, PermissionError, ProcessLookupError):
            continue
        if not command:
            continue
        executable = Path(os.fsdecode(command[0])).name
        if executable in {'ninja', 'soong_ui', 'make', 'm', 'repo'}:
            raise RuntimeError(f'Build/sync process exists: {entry.name} {executable}')


def validate_mount():
    observed = subprocess.check_output([
        'findmnt', '-n', '-o', 'UUID', '--mountpoint', str(BUILD)
    ], text=True).strip()
    if observed != '3ea5abae-6dcc-4f98-9707-e43e14cc3893':
        raise RuntimeError('Unexpected or missing build filesystem')
    if not (SOURCE / '.repo/project-objects').is_dir():
        raise RuntimeError('Local Git object store missing')
    if (SOURCE / 'out').resolve() != BUILD / 'out':
        raise RuntimeError('Unexpected source output target')


def planned_paths():
    paths = [
        SOURCE / 'out.pre-cdrive',
        Path('/home/lotus/.ccache.pre-cdrive'),
        BUILD / 'out',
        BUILD / 'ccache',
    ]
    for snapshot in sorted(ARTIFACTS.glob('evox-a16-x605f-bp4a-*')):
        if not snapshot.is_dir() or snapshot.is_symlink():
            continue
        paths.extend(snapshot.glob('**/extracted-check'))
        if snapshot != FINAL:
            paths.extend(snapshot.glob('*.img'))
            paths.extend(snapshot.glob('six-gib-option/*.img'))
    for providers in sorted(AUDIT.glob('saved-*-providers')):
        if providers.is_dir() and not providers.is_symlink():
            for name in ('system-root', 'factory-apex'):
                paths.append(providers / name)
    paths.append(AUDIT / 'system-size-adbauth-v2-20261003/EXPERIMENTAL-filesystem-minimized-no-AVB.img')
    for directory, filename in (
        ('vendor-usb-two-byte-image-20261003', 'vendor-usb-syntax-candidate.img'),
        ('vendor-usb-hci-three-byte-image-20261003', 'vendor-usb-hci-candidate.img'),
        ('vendor-usb-hci-systemuid-image-isolation-v1-20261003', 'vendor-usb-hci-systemuid-candidate.img'),
    ):
        paths.append(AUDIT / directory / filename)
    return sorted(set(paths))


def validate_path(path):
    allowed_roots = (
        SOURCE / 'out.pre-cdrive',
        Path('/home/lotus/.ccache.pre-cdrive'),
        BUILD / 'out',
        BUILD / 'ccache',
        ARTIFACTS,
    )
    if path.is_symlink() or path.resolve() != path:
        raise RuntimeError(f'Refusing redirected deletion: {path}')
    if path == ARTIFACTS or not any(path == root or root in path.parents for root in allowed_roots):
        raise RuntimeError(f'Outside cleanup roots: {path}')
    if any(path == kept or path in kept.parents for kept in EXPECTED):
        raise RuntimeError(f'Protected final artifact: {path}')
    if os.path.ismount(path):
        raise RuntimeError(f'Refusing mounted deletion root: {path}')
    if path.is_dir():
        for directory, children, files in os.walk(path, followlinks=False):
            for child in children:
                candidate = Path(directory) / child
                if not candidate.is_symlink() and os.path.ismount(candidate):
                    raise RuntimeError(f'Nested mount in cleanup path: {candidate}')


def main():
    parser = argparse.ArgumentParser(description='Allowlisted cleanup; preserves sources, downloads and final images.')
    parser.add_argument('--execute', action='store_true')
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    ensure_quiet()
    validate_mount()
    paths = [path for path in planned_paths() if path.exists()]
    for path in paths:
        validate_path(path)
    report = {
        'executed': False,
        'paths': [str(path) for path in paths],
        'preserved': {},
        'removed': [],
        'source_git_objects_preserved': True,
        'download_caches_preserved': True,
        'missing_previous_delivery': '/mnt/e/TB-X605F-firmware-research/final-offline-candidates-20261003-isolation-v2',
        'missing_previous_resukisu_boot': True,
    }
    for path, expected in EXPECTED.items():
        actual = digest(path)
        if actual != expected:
            raise RuntimeError(f'Final artifact hash mismatch: {path}')
        report['preserved'][str(path)] = actual
    if args.report.resolve() in paths or any(path in args.report.resolve().parents for path in paths):
        raise RuntimeError('Report would be deleted')
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + '\n')
    if args.execute:
        if os.path.ismount('/home/lotus/.ccache'):
            raise RuntimeError('Unmount the ccache bind before executing cleanup')
        retained_host = ARTIFACTS / 'retained-host-tools-20261025'
        if not retained_host.exists():
            shutil.copytree(BUILD / 'out/host', retained_host, symlinks=False)
        for name in ('avbtool', 'checkvintf', 'debugfs', 'e2fsck', 'secilc', 'simg2img', 'unpack_bootimg'):
            original = BUILD / 'out/host/linux-x86/bin' / name
            retained = retained_host / 'linux-x86/bin' / name
            if not retained.is_file() or digest(original) != digest(retained):
                raise RuntimeError(f'Host tool retention failed: {name}')
        ensure_quiet()
        for path in paths:
            validate_path(path)
            if path.is_dir():
                shutil.rmtree(path)
            else:
                path.unlink()
            report['removed'].append(str(path))
            args.report.write_text(json.dumps(report, indent=2) + '\n')
        (BUILD / 'out').mkdir(exist_ok=True)
        (BUILD / 'ccache').mkdir(exist_ok=True)
        for path, expected in EXPECTED.items():
            if digest(path) != expected:
                raise RuntimeError(f'Post-cleanup artifact mismatch: {path}')
        validate_mount()
        report['executed'] = True
        args.report.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'execute': report['executed'], 'planned_paths': len(paths), 'removed_paths': len(report['removed']), 'protected_images': len(EXPECTED)}))


if __name__ == '__main__':
    main()
