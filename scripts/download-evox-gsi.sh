#!/usr/bin/env bash
set -Eeuo pipefail

release_tag='2026-09-20'
file_name='EvoX-11.11-GSI_treble_arm64-ab-GAPPS-20260920.img.xz'
expected_bytes='1537972692'
url="https://github.com/Doze-off/EvoX_treble/releases/download/${release_tag}/${file_name}"
artifact_dir="${1:-${X605F_ARTIFACT_DIR:-$HOME/TB-X605F-artifacts/evox-gsi-${release_tag}}}"
artifact_path="$artifact_dir/$file_name"

for tool in curl xz sha256sum stat; do
    command -v "$tool" >/dev/null 2>&1 || {
        printf 'Required tool is missing: %s\n' "$tool" >&2
        exit 2
    }
done

mkdir -p "$artifact_dir"
if [[ ! -f "$artifact_path" ]] || [[ "$(stat -c '%s' "$artifact_path")" != "$expected_bytes" ]]; then
    curl --fail --location --continue-at - --retry 5 --retry-all-errors --retry-delay 2 \
        "$url" -o "$artifact_path"
fi

actual_bytes="$(stat -c '%s' "$artifact_path")"
if [[ "$actual_bytes" != "$expected_bytes" ]]; then
    printf 'Size mismatch: expected %s bytes, got %s bytes. Partial file retained for resume.\n' \
        "$expected_bytes" "$actual_bytes" >&2
    exit 1
fi

xz --test "$artifact_path"
sha256sum "$artifact_path" | tee "$artifact_path.sha256"
xz --list --verbose "$artifact_path"
printf 'Saved verified xz stream: %s\n' "$artifact_path"
printf 'The SHA-256 above is locally computed; the release API did not provide a publisher checksum in the metadata checked for this snapshot.\n'
