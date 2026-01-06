# Get all installed programs from the Registry
$RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$InstalledApps = Get-ItemProperty $RegistryPaths | 
    Where-Object { $_.DisplayName -ne $null } | 
    Select-Object DisplayName, InstallLocation, DisplayIcon, UninstallString |
    Sort-Object DisplayName

# Define Start Menu Paths for checking
$UserStartMenu = [Environment]::GetFolderPath("Programs")
$CommonStartMenu = [Environment]::GetFolderPath("CommonPrograms")

function Clean-ProgramName ($RawName) {
    $Clean = $RawName -replace '\s*\(.*?\)', ''
    $Clean = $Clean -replace '\s*v?\d+(\.\d+)+', ''
    $Clean = $Clean -replace '\s*(19|20)\d{2}', ''
    return $Clean.Trim(" -")
}

$Results = @()
$Index = 1

foreach ($App in $InstalledApps) {
    # Path Fallback Logic
    $RawPath = $App.InstallLocation
    if (-not $RawPath -and $App.DisplayIcon) { 
        $RawPath = Split-Path ($App.DisplayIcon -replace ',\d+$', '').Trim('"') -Parent 
    }
    if (-not $RawPath -and $App.UninstallString) { 
        $RawPath = Split-Path ($App.UninstallString -replace '(?i)uninst.*', '').Trim('"') -Parent 
    }

    $Drive = if ($RawPath -match "^([A-Z]:)") { $Matches[1] } else { "Unknown" }
    $CleanName = Clean-ProgramName $App.DisplayName

    # CHECK IF IN START MENU
    # We check for the Registry Name OR the Clean Name as a .lnk file
    $InStart = "No"
    $SearchPatterns = @("$($App.DisplayName).lnk", "$CleanName.lnk")
    foreach ($Pattern in $SearchPatterns) {
        if (Test-Path (Join-Path $UserStartMenu $Pattern)) { $InStart = "Yes"; break }
        if (Test-Path (Join-Path $CommonStartMenu $Pattern)) { $InStart = "Yes"; break }
    }

    $Results += [PSCustomObject]@{
        ID             = $Index
        InStartMenu    = $InStart
        CleanName      = $CleanName
        Drive          = $Drive
        RegistryName   = $App.DisplayName
        InstallPath    = $RawPath
        IconPath       = $App.DisplayIcon
    }
    $Index++
}

# Display Table - Sorted so "No" (Missing) items appear at the top for convenience
$Results | Sort-Object InStartMenu | Format-Table ID, InStartMenu, CleanName, Drive, RegistryName -AutoSize

Write-Host "`n--- START MENU SHORTCUT CREATOR ---" -ForegroundColor Cyan
Write-Host "Tip: Items marked 'No' are missing from your Start Menu." -ForegroundColor Gray
$InputIds = Read-Host "Enter IDs to add (e.g., 1,5,12)"

if ($InputIds) {
    $TargetIds = $InputIds.Split(',').Trim()
    foreach ($Id in $TargetIds) {
        $TargetApp = $Results | Where-Object { $_.ID -eq $Id }
        $FinalPath = $TargetApp.InstallPath.Trim('"')

        if ($FinalPath -and (Test-Path $FinalPath)) {
            $Exes = Get-ChildItem -Path $FinalPath -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue | 
                    Where-Object { $_.Name -notmatch "uninst|setup|update|patch|helper|crashreporter|config|dotnet|vc_redist" }

            $BestExe = $Exes | Where-Object { $_.Name -like "*$($TargetApp.CleanName.Split(' ')[0])*"} | Select-Object -First 1
            if (-not $BestExe) { $BestExe = $Exes | Sort-Object Length -Descending | Select-Object -First 1 }
            
            if ($BestExe) {
                $WshShell = New-Object -ComObject WScript.Shell
                $ShortcutPath = Join-Path $UserStartMenu "$($TargetApp.CleanName).lnk"
                $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
                $Shortcut.TargetPath = $BestExe.FullName
                $Shortcut.WorkingDirectory = $FinalPath
                
                if ($TargetApp.IconPath) {
                    $CleanIcon = ($TargetApp.IconPath -replace ',\d+$', '').Trim('"')
                    if (Test-Path $CleanIcon) { $Shortcut.IconLocation = $TargetApp.IconPath }
                }
                
                $Shortcut.Save()
                Write-Host "SUCCESS: Created '$($TargetApp.CleanName)'" -ForegroundColor Green
            } else {
                Write-Host "FAIL: No executable found for $($TargetApp.RegistryName)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "SKIP: ID $Id has no valid path." -ForegroundColor Red
        }
    }
}
