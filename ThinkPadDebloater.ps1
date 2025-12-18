<#
.SYNOPSIS
    ThinkPad 11E "Forscan & ADB Only" Debloater
    Author: Antigravity
    Date: 2025-12-18
    
.DESCRIPTION
    Aggressively debloats Windows 10 for a dedicated Lenovo ThinkPad 11E.
    Removes Telemetry, Bloatware, and non-essential services.
    Preserves: Windows Update, Chrome, Forscan, ADB.
#>

# --- UTILITY FUNCTIONS ---

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

function Assert-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Clear-Host
        Write-Warning "================================================================"
        Write-Warning " ERROR: SCRIPT NOT RUNNING AS ADMINISTRATOR"
        Write-Warning "================================================================"
        Write-Warning " You MUST right-click and select 'Run as Administrator'."
        Write-Warning " Or use the 'RunDebloater.bat' file included."
        Write-Warning "================================================================"
        Start-Sleep -Seconds 10
        exit
    }
}

function New-SysRestorePoint {
    param([string]$Description = "ThinkPad Debloat Pre-Flight")
    Write-Log "Creating System Restore Point: $Description" "Cyan"
    try {
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Log "Restore point created successfully." "Green"
    }
    catch {
        Write-Log "Failed to create restore point. Ensure System Restore is enabled." "Red"
        Write-Warning $_.Exception.Message
        $choice = Read-Host "Continue without restore point? (Y/N)"
        if ($choice -ne 'Y') { exit }
    }
}

# --- DEBLOAT FUNCTIONS ---

function Remove-Bloatware {
    Write-Log "Removing Bloatware (UWP Apps)..." "Yellow"
    
    # Whitelist: Apps to KEEP
    # Calculator, Photos, Store (optional, usually good to keep for updates), Camera (needed?)
    # User said "Kill it all", but Store is often needed for updates/installing specific things.
    # We will keep Store connectivity components but kill the storefront if requested, 
    # but usually easier to just kill the consumer apps.
    
    $AppList = @(
        # Core System Apps (User requested "Kill it all")
        "Microsoft.WindowsStore"     # Microsoft Store
        "Microsoft.StorePurchaseApp" # Store Backend
        "Microsoft.Services.Store.Engagement"
        "Microsoft.DesktopAppInstaller" # App Installer (winget might break, but user requested)

        # Communications
        "microsoft.windowscommunicationsapps" # Mail & Calendar
        "Microsoft.SkypeApp"
        "Microsoft.GetHelp"
        "Microsoft.YourPhone"
        "Microsoft.People"
        
        # Entertainment / Consumables
        "Microsoft.ZuneMusic"
        "Microsoft.ZuneVideo"
        "Microsoft.BingWeather"
        "Microsoft.BingNews"
        "Microsoft.BingFinance"
        "Microsoft.BingSports"
        "Microsoft.MicrosoftSolitaireCollection"
        "Microsoft.XboxApp"
        "Microsoft.Xbox.TCUI"
        "Microsoft.XboxGameOverlay"
        "Microsoft.XboxGamingOverlay"
        "Microsoft.XboxIdentityProvider"
        "Microsoft.XboxSpeechToTextOverlay"
        "Microsoft.GamingApp"
        
        # Office / Productivity
        "Microsoft.MicrosoftOfficeHub"
        "Microsoft.Office.OneNote"
        "Microsoft.OneConnect"
        "Microsoft.StickyNotes"
        
        # 3D / VR
        "Microsoft.Microsoft3DViewer"
        "Microsoft.MixedReality.Portal"
        "Microsoft.Print3D"
        
        # Misc
        "Microsoft.Getstarted"
        "Microsoft.WindowsFeedbackHub"
        "Microsoft.WindowsMaps"
        "Microsoft.WindowsAlarms" # Clock
        "Microsoft.WindowsSoundRecorder"
        "Microsoft.Wallet"
    )

    foreach ($app in $AppList) {
        Write-Host "Processing: $app ..." -NoNewline
        
        # Try to kill the process if it's running
        Get-Process -Name $app -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        
        # 1. Try to remove for Current/All Users
        try {
            $package = Get-AppxPackage -Name $app -AllUsers -ErrorAction Stop
            if ($package) {
                $package | Remove-AppxPackage -AllUsers -ErrorAction Stop
                Write-Host " [REMOVED USER APP]" -ForegroundColor Green
            }
            else {
                Write-Host " [USER APP NOT FOUND]" -ForegroundColor DarkGray -NoNewline
            }
        }
        catch {
            Write-Host " [USER REMOVAL FAILED]" -ForegroundColor Yellow -NoNewline
        }

        # 2. Try to remove Provisioned Package (The "Nuclear" Option for System Apps)
        try {
            # Use -like wildcard on PackageName because DisplayName might be "Microsoft Store" vs "Microsoft.WindowsStore"
            $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "*$app*" }
            
            if ($prov) {
                $prov | Remove-AppxProvisionedPackage -Online -ErrorAction Stop | Out-Null
                Write-Host " [REMOVED PROVISIONED]" -ForegroundColor Green
            }
            else {
                # Only log this for debugging if user asked, otherwise it spams
                # Write-Host " [PROV NOT FOUND]" -ForegroundColor DarkGray
            }
        }
        catch {
            # Only complain if BOTH failed and it wasn't just "not found"
            # We don't need to log this failure heavily if the user app is already gone
        }
        
        Write-Host "" # Newline after processing line
    }
    Write-Log "Bloatware removal complete." "Green"
}

function Disable-TelemetryAndServices {
    Write-Log "Disabling Telemetry and Services..." "Yellow"

    # Services
    $Services = @(
        "DiagTrack",                 # Connected User Experiences and Telemetry
        "dmwappushservice",          # WAP Push Message Routing Service
        "MapsBroker",                # Downloaded Maps Manager
        "lfsvc",                     # Geolocation Service
        "WerSvc",                    # Windows Error Reporting Service
        "WSearch",                   # Windows Search (High CPU usage indexer)
        "SysMain",                   # Superfetch (Preloads apps into RAM, disabling frees memory)
        "XblAuthManager",            # Xbox Live Auth Manager
        "XblGameSave",               # Xbox Live Game Save
        "XboxNetApiSvc",             # Xbox Live Networking Service
        "Spooler",                   # Print Spooler (Unlikely needed for car tuning)
        "Fax",                       # Fax Service
        "RetailDemo",                # Windows Retail Demo Service
        "SCardSvr",                  # Smart Card Service
        "RemoteRegistry"             # Remote Registry (Security/Performance)
    )

    foreach ($svc in $Services) {
        if (Get-Service $svc -ErrorAction SilentlyContinue) {
            Stop-Service $svc -Force -ErrorAction SilentlyContinue
            Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "Disabled Service: $svc" -ForegroundColor DarkGray
        }
    }

    # Registry Tweaks for Telemetry
    Write-Log "Applying Registry Tweaks..." "Yellow"
    
    $Tweaks = @(
        # Disable Telemetry
        @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 0; Type = "DWord" }
        # Disable Advertising ID
        @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Value = 0; Type = "DWord" }
        # Disable Cortana / Search Bing
        @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowCortana"; Value = 0; Type = "DWord" }
        @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "DisableWebSearch"; Value = 1; Type = "DWord" }
        # Disable Location
        @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; Name = "DisableLocation"; Value = 1; Type = "DWord" }
        # Disable Background Apps (Global Toggle)
        @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"; Name = "GlobalUserDisabled"; Value = 1; Type = "DWord" }
        @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "BackgroundAppGlobalToggle"; Value = 0; Type = "DWord" }
    )

    foreach ($tweak in $Tweaks) {
        if (!(Test-Path $tweak.Path)) { New-Item -Path $tweak.Path -Force | Out-Null }
        New-ItemProperty -Path $tweak.Path -Name $tweak.Name -Value $tweak.Value -PropertyType $tweak.Type -Force | Out-Null
        Write-Host "Set Reg: $($tweak.Path)\$($tweak.Name)" -ForegroundColor DarkGray
    }
    
    Write-Log "Telemetry and Services configuration complete." "Green"
}

function Optimize-Visuals {
    Write-Log "Optimizing Visual Effects for Performance..." "Yellow"
    
    # Adjust for best performance (Registry)
    # 0 = Let Windows choose, 1 = Best Appearance, 2 = Best Performance, 3 = Custom
    $visualPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    if (!(Test-Path $visualPath)) { New-Item -Path $visualPath -Force | Out-Null }
    Set-ItemProperty -Path $visualPath -Name "VisualFXSetting" -Value 2

    # High Performance Power Plan
    Write-Log "Setting Power Plan to High Performance..." "Yellow"
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    
    Write-Log "Visual effects set to 'Best Performance' and Power Plan updated." "Green"
}

function Test-Tools {
    Write-Log "Verifying Critical Tools..." "Cyan"
    
    # Check for ADB
    try {
        $adb = Get-Command "adb" -ErrorAction Stop
        Write-Log "ADB found at: $($adb.Source)" "Green"
    }
    catch {
        Write-Log "ADB not found in PATH." "Red"
    }

    # Check for Chrome (Default Install Locations)
    $chromePath = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
    $chromePathx86 = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
    
    if ((Test-Path $chromePath) -or (Test-Path $chromePathx86)) {
        Write-Log "Chrome found." "Green"
    }
    else {
        Write-Log "Chrome installation not detected in standard paths." "Yellow"
    }

    # Forscan Check (Assuming standard install or user knows)
    Write-Log "Ensure Forscan is working after reboot." "White"

    # Network Check
    Write-Log "Testing Network Connectivity..." "Cyan"
    try {
        if (Test-Connection -ComputerName "google.com" -Count 1 -Quiet) {
            Write-Log "Internet Connection: OK" "Green"
        }
        else {
            Write-Log "Internet Connection: FAILED (Check WiFi)" "Red"
        }
    }
    catch {
        Write-Log "Could not test connection." "Yellow"
    }

    # Bluetooth Check
    if (Get-Service "bthserv" -ErrorAction SilentlyContinue | Where-Object Status -eq 'Running') {
        Write-Log "Bluetooth Service: RUNNING (OK)" "Green"
    }
    else {
        Write-Log "Bluetooth Service: STOPPED (Enable if needed)" "Yellow"
    }
}

# --- MENU SYSTEM ---

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   ThinkPad 11E DEBLOATER (Forscan Ed.) " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "1. Create System Restore Point (Recommended First!)"
    Write-Host "2. Remove ALL Bloatware (Mail, Xbox, News, Weather, etc.)"
    Write-Host "3. Disable Telemetry & Unnecessary Services"
    Write-Host "4. Optimize Visual Effects (Performance Mode)"
    Write-Host "5. RUN ALL (Steps 1-4)"
    Write-Host "6. Verify Critical Tools (ADB/Chrome)"
    Write-Host "Q. Quit"
    Write-Host "========================================" -ForegroundColor Cyan
}

# --- MAIN EXECUTION ---

Assert-Admin

do {
    Show-Menu
    $userChoice = Read-Host "Select an option"
    switch ($userChoice) {
        '1' { New-SysRestorePoint }
        '2' { Remove-Bloatware }
        '3' { Disable-TelemetryAndServices }
        '4' { Optimize-Visuals }
        '5' {
            New-SysRestorePoint
            Remove-Bloatware
            Disable-TelemetryAndServices
            Optimize-Visuals
            Write-Log "All tasks completed. Network/WiFi drivers are untouched." "Green"
            Start-Sleep -Seconds 2
        }
        '6' { Test-Tools; pause }
        'Q' { exit }
        'q' { exit }
        default { Write-Warning "Invalid Option" }
    }
    pause
} until ($false)
