[CmdletBinding()]
param(
    [string]$OutputRoot = (Join-Path $PSScriptRoot '../../artifacts/device-baseline')
)

# Read-only ADB/Fastboot collection. This script never reboots, erases, flashes, or writes to the device.
$ErrorActionPreference = 'Stop'

$adbCommand = Get-Command adb.exe -ErrorAction SilentlyContinue
if ($null -eq $adbCommand) { $adbCommand = Get-Command adb -ErrorAction SilentlyContinue }
if ($null -eq $adbCommand) { throw 'adb is not on PATH. Install Android platform-tools on the Windows machine first.' }

$adbPath = $adbCommand.Source
$deviceList = @(& $adbPath devices -l 2>&1)
$online = @($deviceList | ForEach-Object {
    if ($_ -match '^\s*(\S+)\s+device(?:\s|$)') { $Matches[1] }
})

if ($online.Count -ne 1) {
    $deviceList | ForEach-Object { Write-Output $_ }
    throw "Expected exactly one authorized ADB device; found $($online.Count). No device data was collected."
}

$serial = [string]$online[0]
$identityNames = @(
    'ro.product.model',
    'ro.product.device',
    'ro.product.name',
    'ro.product.vendor.model',
    'ro.product.vendor.device',
    'ro.build.product'
)
$identity = foreach ($property in $identityNames) {
    $value = (& $adbPath -s $serial shell getprop $property 2>&1 | Out-String).Trim()
    "$property=$value"
}
$identityText = $identity -join "`n"
if ($identityText -notmatch '(?i)TB-X605F') {
    Write-Output $identityText
    throw 'ADB properties do not identify TB-X605F. Collection stopped before capturing the full baseline.'
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outputDir = Join-Path $OutputRoot $stamp
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
$identityText | Set-Content -Encoding utf8 (Join-Path $outputDir 'identity.txt')
$deviceList | Set-Content -Encoding utf8 (Join-Path $outputDir 'adb-devices.txt')

function Save-AdbOutput {
    param([string]$Name, [string[]]$RemoteArgs)
    $args = @('-s', $serial, 'shell') + $RemoteArgs
    $output = @(& $adbPath @args 2>&1)
    $exitCode = $LASTEXITCODE
    $output | Set-Content -Encoding utf8 (Join-Path $outputDir $Name)
    if ($exitCode -ne 0) { Write-Warning "$Name returned exit code $exitCode; output was retained." }
}

Save-AdbOutput -Name 'getprop.txt' -RemoteArgs @('getprop')
Save-AdbOutput -Name 'cmdline.txt' -RemoteArgs @('cat', '/proc/cmdline')
Save-AdbOutput -Name 'partitions.txt' -RemoteArgs @('cat', '/proc/partitions')
Save-AdbOutput -Name 'by-name.txt' -RemoteArgs @('ls', '-l', '/dev/block/by-name')
Save-AdbOutput -Name 'mount.txt' -RemoteArgs @('cat', '/proc/mounts')
Save-AdbOutput -Name 'df.txt' -RemoteArgs @('df', '-h')
Save-AdbOutput -Name 'fstab.txt' -RemoteArgs @('sh', '-c', 'for f in /vendor/etc/fstab* /system/vendor/etc/fstab*; do [ -f "$f" ] && { echo "=== $f ==="; cat "$f"; }; done')

@(
    "Collected: $(Get-Date -Format o)",
    "ADB serial: $serial",
    'Identity matched TB-X605F: yes',
    'Collection is read-only. Treat these raw files as private device data; do not commit them.'
) | Set-Content -Encoding utf8 (Join-Path $outputDir 'collection.txt')

Write-Output "Read-only device baseline saved to: $outputDir"
