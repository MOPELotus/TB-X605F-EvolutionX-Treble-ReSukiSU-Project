#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
    printf 'Usage: %s --phase sync|build EXISTING_ANDROID_SOURCE_OR_BUILD_DIRECTORY\n' "$0" >&2
}

if [[ $# -ne 3 || "$1" != '--phase' || ( "$2" != 'sync' && "$2" != 'build' ) || ! -d "$3" ]]; then
    usage
    exit 2
fi

phase="$2"
target_dir="$(cd "$3" && pwd -P)"
if [[ "$phase" == sync ]]; then
    min_disk_bytes=$((400 * 1000 * 1000 * 1000))
    required_tools=(git git-lfs repo python3 curl xz sha256sum)
else
    min_disk_bytes=$((150 * 1000 * 1000 * 1000))
    required_tools=(git java make python3 curl xz sha256sum)
fi
min_mem_kib=$((64 * 1024 * 1024))
available_bytes="$(df -PB1 --output=avail "$target_dir" | tail -n 1 | tr -d ' ')"
total_mem_kib="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
total_mem_bytes=$((total_mem_kib * 1024))
cpu_count="$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc)"
fstype="$(findmnt -n -o FSTYPE --target "$target_dir" 2>/dev/null || printf unknown)"
mountpoint="$(findmnt -n -o TARGET --target "$target_dir" 2>/dev/null || printf unknown)"

printf 'Android %s preflight (read-only)\n' "$phase"
printf '  OS: %s\n' "$(uname -srm)"
printf '  Directory: %s\n' "$target_dir"
printf '  Filesystem: %s on %s\n' "$fstype" "$mountpoint"
printf '  Online CPUs: %s\n' "$cpu_count"
printf '  RAM visible to Linux: %.1f GiB\n' "$(awk -v n="$total_mem_bytes" 'BEGIN {print n/1024/1024/1024}')"
printf '  Free bytes on source filesystem: %s (%.1f GB)\n' "$available_bytes" "$(awk -v n="$available_bytes" 'BEGIN {print n/1000/1000/1000}')"

problems=0
if (( available_bytes < min_disk_bytes )); then
    if [[ "$phase" == sync ]]; then
        printf '  BLOCKED: AOSP recommends at least 400 GB free for checkout plus build output before source sync.\n' >&2
    else
        printf '  BLOCKED: reserve at least 150 GB free for Android build output after checkout.\n' >&2
    fi
    problems=$((problems + 1))
fi
if (( total_mem_kib < min_mem_kib )); then
    printf '  NOTE: AOSP documents a 64 GB host RAM minimum; Linux sees less. On WSL, check .wslconfig and keep BUILD_JOBS modest.\n' >&2
fi
if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null && [[ "$target_dir" == /mnt/* ]]; then
    printf '  BLOCKED: this path is on a Windows-mounted filesystem; use the WSL Linux filesystem for source and build output.\n' >&2
    problems=$((problems + 1))
fi

for tool in "${required_tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf '  %-10s %s\n' "$tool:" "$(command -v "$tool")"
    else
        printf '  MISSING    %s\n' "$tool" >&2
        problems=$((problems + 1))
    fi
done

if command -v java >/dev/null 2>&1; then
    java_version_line="$(java -version 2>&1 | head -n 1)"
    java_major="$(java -version 2>&1 | awk -F '"' '/version/ {split($2, v, "."); print v[1]; exit}')"
    printf '  Java:      %s\n' "$java_version_line"
    if [[ "$phase" == build && "$java_major" != 17 ]]; then
        printf '  BLOCKED: TrebleApp release build requires Java 17; found major version %s.\n' "${java_major:-unknown}" >&2
        problems=$((problems + 1))
    fi
fi

if (( problems > 0 )); then
    printf '\nPreflight found %s blocking condition(s); resolve them before continuing.\n' "$problems" >&2
    exit 2
fi

printf '\nPreflight passed the %s storage, environment, and tool-presence checks.\n' "$phase"
