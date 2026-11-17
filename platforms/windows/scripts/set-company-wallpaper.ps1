# Sets the company desktop wallpaper for every user on this PC, including
# users who sign in for the first time later. Runs as SYSTEM from Fleet.
# The wallpaper is locked (users can't change it) and applies at next sign-in.

# TODO: Set this to the wallpaper's location once it's decided, for example
# "C:\ProgramData\Company\wallpaper.jpg" or a UNC path the PC can read.
$WallpaperPath = ""

# 10 = Fill. Other values: 0 = Center, 2 = Stretch, 6 = Fit, 22 = Span.
$WallpaperStyle = "10"

if ([string]::IsNullOrWhiteSpace($WallpaperPath)) {
    Write-Output "WallpaperPath is blank. Set it in this script before running."
    exit 1
}
if (-not (Test-Path -LiteralPath $WallpaperPath)) {
    Write-Output "Wallpaper not found at $WallpaperPath"
    exit 1
}

$policyKey = "Software\Microsoft\Windows\CurrentVersion\Policies\System"

function Set-WallpaperPolicy([string]$HiveRoot) {
    $key = "Registry::$HiveRoot\$policyKey"
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    Set-ItemProperty -Path $key -Name "Wallpaper" -Value $WallpaperPath -Type String
    Set-ItemProperty -Path $key -Name "WallpaperStyle" -Value $WallpaperStyle -Type String
}

function Set-ForHiveFile([string]$Name, [string]$HivePath) {
    $mount = "HKU\FleetWallpaper_$Name"
    & reg.exe load $mount $HivePath | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Output "Skipped $Name (couldn't load $HivePath)"; return }
    try { Set-WallpaperPolicy "HKEY_USERS\FleetWallpaper_$Name" }
    finally {
        [GC]::Collect(); [GC]::WaitForPendingFinalizers()
        & reg.exe unload $mount | Out-Null
    }
    Write-Output "Set for $Name"
}

# Existing local and domain/Entra users.
$profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" |
    Where-Object { $_.PSChildName -match '^S-1-(5-21|12-1)-' }
foreach ($p in $profiles) {
    $sid = $p.PSChildName
    if (Test-Path "Registry::HKEY_USERS\$sid") {
        Set-WallpaperPolicy "HKEY_USERS\$sid"   # Signed in: hive already loaded
        Write-Output "Set for $sid"
    } else {
        $hive = Join-Path (Get-ItemProperty $p.PSPath).ProfileImagePath "NTUSER.DAT"
        if (Test-Path $hive) { Set-ForHiveFile $sid $hive }
    }
}

# Template for users who haven't signed in yet.
$defaultHive = Join-Path $env:SystemDrive "Users\Default\NTUSER.DAT"
if (Test-Path $defaultHive) { Set-ForHiveFile "Default" $defaultHive }

Write-Output "Done. The wallpaper applies the next time each user signs in."
exit 0
