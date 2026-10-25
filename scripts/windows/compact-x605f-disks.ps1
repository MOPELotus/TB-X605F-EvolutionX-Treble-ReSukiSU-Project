param(
    [switch]$Execute,
    [string]$LogDirectory = "$PSScriptRoot\..\..\.codex-patch-stage"
)

$ErrorActionPreference = 'Stop'
$paths = @(
    'C:\WSL\AndroidBuild\android-build-clean.vhdx',
    'E:\WSL\Ubuntu\ext4.vhdx'
)
$before = foreach ($path in $paths) {
    $item = Get-Item -LiteralPath $path
    if ($item.PSIsContainer -or $item.FullName -ne $path -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Unexpected disk path: $path"
    }
    [pscustomobject]@{ Path = $path; Bytes = $item.Length }
}
if (-not $Execute) {
    $before | ConvertTo-Json
    return
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Administrator rights are required. This script does not stop WSL automatically.'
}
$env:WSL_UTF8 = '1'
$running = (& wsl.exe --list --running --quiet) -join ''
if ($LASTEXITCODE -ne 0 -or $running.Trim([char]0).Trim()) {
    throw 'WSL must already be stopped after guest sync and trim.'
}
foreach ($path in $paths) {
    $disk = Get-DiskImage -ImagePath $path
    if ($disk.Attached) {
        throw "Disk is still attached: $path"
    }
}

[IO.Directory]::CreateDirectory($LogDirectory) | Out-Null
$results = @()
foreach ($path in $paths) {
    $name = [IO.Path]::GetFileNameWithoutExtension($path)
    $instructions = Join-Path $LogDirectory "$name-compact.diskpart.txt"
    $log = Join-Path $LogDirectory "$name-compact.log"
    [IO.File]::WriteAllLines($instructions, @("select vdisk file=`"$path`"", 'compact vdisk', 'exit'), [Text.Encoding]::ASCII)
    $output = & diskpart.exe /s $instructions 2>&1
    $exitCode = $LASTEXITCODE
    $output | Out-File -LiteralPath $log -Encoding utf8
    if ($exitCode -ne 0) {
        throw "DiskPart failed for $path; inspect $log"
    }
    $initial = $before | Where-Object { $_.Path -eq $path }
    $results += [pscustomobject]@{
        Path = $path
        BeforeBytes = $initial.Bytes
        AfterBytes = (Get-Item -LiteralPath $path).Length
        DiskPartExit = $exitCode
        Log = $log
    }
}
$results | ConvertTo-Json | Out-File -LiteralPath (Join-Path $LogDirectory 'disk-compaction-results-20261025.json') -Encoding utf8
$results | ConvertTo-Json
