#!/usr/bin/env bash
set -Eeuo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
preflight="$project_root/scripts/preflight-android-build.sh"
apply_patches="$project_root/scripts/apply-x605f-patches.sh"

if [[ $# -ne 1 || ! -d "$1/.repo" ]]; then
    printf 'Usage: %s ANDROID_SOURCE_ROOT (already synced)\n' "$0" >&2
    exit 2
fi

android_top="$(cd "$1" && pwd -P)"
build_jobs="${BUILD_JOBS:-16}"
out_root="$android_top/out"
product_mk="$android_top/device/phh/treble/evox_gsi.mk"

if [[ -n "${OUT_DIR:-}" && "$OUT_DIR" != "$out_root" ]]; then
    printf 'This helper expects OUT_DIR to remain inside the synced source tree at %s; unset the alternate OUT_DIR and retry.\n' "$out_root" >&2
    exit 2
fi

for metadata_file in "$android_top/x605f-source-manifest-lock.xml" "$android_top/x605f-source-sync.txt"; do
    if [[ ! -s "$metadata_file" ]]; then
        printf 'Required source lock/metadata is missing: %s. Run scripts/sync-evox-a16-source.sh first.\n' "$metadata_file" >&2
        exit 2
    fi
done

"$preflight" --phase build "$android_top"
"$apply_patches" "$android_top"

if [[ ! -s "$product_mk" ]] ||
   ! grep -Fxq 'WITH_GMS := true' "$product_mk" ||
   ! grep -Fxq 'TARGET_USES_MINI_GAPPS := false' "$product_mk" ||
   ! grep -Fxq 'TARGET_USES_PICO_GAPPS := false' "$product_mk"; then
    printf 'The EvoX product does not match the expected full-GApps configuration: %s\n' "$product_mk" >&2
    exit 2
fi

if [[ ! -x "$android_top/treble_app/build.sh" ]]; then
    printf 'Treble app build entry point is missing: %s\n' "$android_top/treble_app/build.sh" >&2
    exit 2
fi
(
    cd "$android_top/treble_app"
    ./build.sh release
)
if [[ ! -s "$android_top/treble_app/TrebleApp.apk" ]]; then
    printf 'TrebleApp release APK was not produced.\n' >&2
    exit 1
fi

(
    cd "$android_top"
    # shellcheck disable=SC1091
    source build/envsetup.sh
    lunch evox_gsi-userdebug
    m systemimage -j"$build_jobs"
)

system_image="$out_root/target/product/tdgsi_arm64_ab/system.img"
if [[ ! -s "$system_image" ]]; then
    printf 'Expected product image was not found: %s\n' "$system_image" >&2
    exit 1
fi

build_stamp="$(date -u +%Y%m%dT%H%M%SZ)"
artifact_dir="${X605F_ARTIFACT_DIR:-$HOME/TB-X605F-artifacts/evox-a16-fullgapps-$build_stamp}"
mkdir -p "$artifact_dir"
cp --reflink=auto "$system_image" "$artifact_dir/system.img"
cp "$android_top/x605f-source-manifest-lock.xml" "$artifact_dir/"
cp "$android_top/x605f-source-sync.txt" "$artifact_dir/"
git -C "$android_top/device/phh/treble" diff --binary > "$artifact_dir/device-phh-working-diff.patch"
sha256sum "$artifact_dir/system.img" | tee "$artifact_dir/system.img.sha256"
sha256sum "$artifact_dir/device-phh-working-diff.patch" > "$artifact_dir/device-phh-working-diff.patch.sha256"
printf 'Build output saved to: %s\n' "$artifact_dir"
