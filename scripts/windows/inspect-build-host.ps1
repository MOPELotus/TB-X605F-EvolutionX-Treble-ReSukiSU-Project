[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

Write-Output 'Windows Android build host inspection (read-only)'
Write-Output ('Computer: {0}' -f $env:COMPUTERNAME)

try {
    $computer = Get-CimInstance Win32_ComputerSystem
    Write-Output ('Physical memory: {0:N1} GiB' -f ($computer.TotalPhysicalMemory / 1GB))
} catch {
    Write-Warning "Could not read physical memory: $_"
}

try {
    Get-CimInstance Win32_Processor |
        Select-Object Name, NumberOfCores, NumberOfLogicalProcessors |
        Format-Table -AutoSize | Out-String | Write-Output
} catch {
    Write-Warning "Could not read CPU information: $_"
}

try {
    Get-Volume |
        Where-Object { $_.DriveType -eq 'Fixed' -and $_.Size -gt 0 } |
        Select-Object DriveLetter, FileSystem, @{Name='SizeGiB';Expression={[math]::Round($_.Size / 1GB, 1)}}, @{Name='FreeGiB';Expression={[math]::Round($_.SizeRemaining / 1GB, 1)}} |
        Format-Table -AutoSize | Out-String | Write-Output
} catch {
    Write-Warning "Could not read fixed-volume free space: $_"
}

$wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
if ($null -eq $wsl) {
    Write-Warning 'wsl.exe is unavailable. Android source builds require a supported Linux environment.'
    exit 0
}

Write-Output '--- wsl --status ---'
& $wsl.Source --status 2>&1 | ForEach-Object { Write-Output $_ }
Write-Output '--- wsl --list --verbose ---'
& $wsl.Source --list --verbose 2>&1 | ForEach-Object { Write-Output $_ }
Write-Output '--- Next ---'
Write-Output 'Inside the chosen WSL2 distro, check /proc/meminfo and df -h on the Linux filesystem that will hold both source and out/.'
