#!/usr/bin/env bash
set -Eeuo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
manifest_source="$project_root/manifests/x605f-evox-a16.xml"
preflight="$project_root/scripts/preflight-android-build.sh"
apply_patches="$project_root/scripts/apply-x605f-patches.sh"
manifest_url='https://github.com/Doze-off/EvoX_treble.git'
manifest_branch='16.2'
sync_jobs="${REPO_SYNC_JOBS:-8}"

if [[ $# -ne 1 ]]; then
    printf 'Usage: %s EXISTING_OR_EMPTY_LINUX_SOURCE_DIRECTORY\n' "$0" >&2
    exit 2
fi
source_dir="$(mkdir -p "$1" && cd "$1" && pwd -P)"

if ! command -v repo >/dev/null 2>&1; then
    printf 'repo is required. Install the Android Repo launcher in this Linux environment first.\n' >&2
    exit 2
fi
if ! command -v git >/dev/null 2>&1; then
    printf 'git is required.\n' >&2
    exit 2
fi

if [[ -d "$source_dir/.repo" ]]; then
    manifest_remote="$(git -C "$source_dir/.repo/manifests" config --get remote.origin.url 2>/dev/null || true)"
    if [[ "$manifest_remote" != *'Doze-off/EvoX_treble'* ]]; then
        printf 'Refusing to sync an existing Repo workspace that is not based on Doze-off/EvoX_treble.\n' >&2
        exit 2
    fi
elif [[ -n "$(find "$source_dir" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    printf 'Refusing to initialize a non-empty directory without a Repo workspace: %s\n' "$source_dir" >&2
    exit 2
fi

"$preflight" --phase sync "$source_dir"
cd "$source_dir"
if [[ ! -d "$source_dir/.repo" ]]; then
    repo init -u "$manifest_url" -b "$manifest_branch" --git-lfs
fi

local_manifest_dir="$source_dir/.repo/local_manifests"
local_manifest_path="$local_manifest_dir/x605f-evox-a16.xml"
mkdir -p "$local_manifest_dir"
if [[ -e "$local_manifest_path" ]] && ! cmp -s "$manifest_source" "$local_manifest_path"; then
    printf 'A different local manifest already exists at %s; refusing to overwrite it.\n' "$local_manifest_path" >&2
    exit 2
fi
if [[ ! -e "$local_manifest_path" ]]; then
    install -m 0644 "$manifest_source" "$local_manifest_path"
fi

repo sync -c -j "$sync_jobs"
"$apply_patches" "$source_dir"

repo manifest -r -o "$source_dir/x605f-source-manifest-lock.xml"
manifest_commit='unknown'
if git -C "$source_dir/.repo/manifests" rev-parse --verify HEAD >/dev/null 2>&1; then
    manifest_commit="$(git -C "$source_dir/.repo/manifests" rev-parse HEAD)"
fi
local_manifest_sha="$(sha256sum "$local_manifest_path" | awk '{print $1}')"
patchset_sha="$(find "$project_root/patches/treble" -maxdepth 1 -type f -name '*.patch' -print0 | sort -z | xargs -0 sha256sum | sed "s|$project_root/||" | sha256sum | awk '{print $1}')"
cat > "$source_dir/x605f-source-sync.txt" <<EOF
Synced at UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Manifest URL: $manifest_url
Manifest branch requested: $manifest_branch
Manifest repository commit: $manifest_commit
Local manifest SHA-256: $local_manifest_sha
Treble patchset SHA-256: $patchset_sha
Repo manifest lock: x605f-source-manifest-lock.xml
Sync jobs: $sync_jobs
EOF

printf 'Source sync complete: %s\n' "$source_dir"
printf 'Review x605f-source-manifest-lock.xml and x605f-source-sync.txt before building.\n'
