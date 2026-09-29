[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ExpectedSerial,
    [string]$OutputRoot = (Join-Path $PSScriptRoot '../../artifacts/device-baseline')
)

# The user must place the previously identified tablet in bootloader/fastboot mode.
# This script only runs `fastboot devices` and `fastboot getvar all`.
$ErrorActionPreference = 'Stop'

$fastbootCommand = Get-Command fastboot.exe -ErrorAction SilentlyContinue
if ($null -eq $fastbootCommand) { $fastbootCommand = Get-Command fastboot -ErrorAction SilentlyContinue }
if ($null -eq $fastbootCommand) { throw 'fastboot is not on PATH. Install Android platform-tools on the Windows machine first.' }

$fastbootPath = $fastbootCommand.Source
$deviceList = @(& $fastbootPath devices -l 2>&1)
$serials = @($deviceList | ForEach-Object {
    if ($_ -match '^\s*(\S+)\s+fastboot(?:\s|$)') { $Matches[1] }
})
if ($serials.Count -ne 1 -or $serials[0] -ne $ExpectedSerial) {
    $deviceList | ForEach-Object { Write-Output $_ }
    throw 'Fastboot did not report exactly the serial previously confirmed by the ADB baseline. No getvar collection was performed.'
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outputDir = Join-Path $OutputRoot ("fastboot-$stamp")
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
$deviceList | Set-Content -Encoding utf8 (Join-Path $outputDir 'fastboot-devices.txt')
$getvarOutput = @(& $fastbootPath -s $ExpectedSerial getvar all 2>&1)
$exitCode = $LASTEXITCODE
$getvarOutput | Set-Content -Encoding utf8 (Join-Path $outputDir 'fastboot-getvar-all.txt')
@(
    "Collected: $(Get-Date -Format o)",
    "Fastboot serial: $ExpectedSerial",
    'Serial matched the ADB baseline supplied by the operator: yes',
    'Collection is read-only. No reboot, erase, flash, or partition command was run.'
) | Set-Content -Encoding utf8 (Join-Path $outputDir 'collection.txt')

if ($exitCode -ne 0) { Write-Warning "fastboot getvar all returned exit code $exitCode; output was retained." }
Write-Output "Read-only Fastboot baseline saved to: $outputDir"
