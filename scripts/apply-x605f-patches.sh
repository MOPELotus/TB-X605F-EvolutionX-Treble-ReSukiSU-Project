#!/usr/bin/env bash
set -Eeuo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

if [[ $# -ne 1 || ! -d "$1/.repo" || ! -d "$1/device/phh/treble/.git" && ! -f "$1/device/phh/treble/.git" ]]; then
    printf 'Usage: %s ANDROID_SOURCE_ROOT (must contain .repo and device/phh/treble)\n' "$0" >&2
    exit 2
fi

source_root="$(cd "$1" && pwd -P)"
tree="$source_root/device/phh/treble"
shopt -s nullglob
patches=("$project_root"/patches/treble/*.patch)
if (( ${#patches[@]} == 0 )); then
    printf 'No Treble patches found.\n'
    exit 0
fi

for patch in "${patches[@]}"; do
    if git -C "$tree" apply --check "$patch"; then
        git -C "$tree" apply "$patch"
        printf 'Applied %s\n' "${patch#"$project_root"/}"
    elif git -C "$tree" apply --reverse --check "$patch"; then
        printf 'Already applied %s\n' "${patch#"$project_root"/}"
    else
        printf 'Patch does not apply cleanly to %s: %s\n' "$tree" "$patch" >&2
        exit 1
    fi
done
