# ThinkPad 11E Debloater (Forscan Edition)

![Views](https://komarev.com/ghpvc/?username=YourUsername&label=Views&color=blue&style=flat)

A heavy-duty PowerShell debloater script specifically tuned for low-power laptops (like the **ThinkPad 11E** with Pentium/Celeron CPUs) dedicated to automotive diagnostics (**Forscan**) and Android debugging (**ADB**).

This script aggressively strips Windows 10 down to the bare metal to maximize RAM availability and CPU responsiveness.

## 🚀 Features

### 🛡️ Aggressive Debloat
- **Removes UWP Bloatware**: Nuclear option. Removes Mail, Calendar, Xbox, News, Weather, Solitaire, and 3D Viewer.
- **Kills Microsoft Store**: (Optional but default in "Run All") Removes the Store itself to prevent auto-updates of candy crush junk.
- **Uninstalls OneDrive**: Completely removes the OneDrive sync client to save massive background resources.

### 💨 Performance Tuning
- **High Performance Power Plan**: Forces CPU to run at higher clocks (prevents aggressive throttling).
- **Disables Visual Effects**: Turns off animations, shadows, and translucency for snappy UI response.
- **Disables SysMain (Superfetch)**: Stops Windows from pre-loading apps into RAM (Critical for 4GB/8GB RAM systems).
- **Disables Hibernation**: Frees up several GB of disk space and ensures a "Clean Boot" every time (Better for ODB2 driver stability).

### 🚫 Telemetry & Background Noise
- **Privacy Tweaks**: Disables DiagTrack (Connected User Experiences and Telemetry).
- **Service Killer**: Disables Print Spooler, Fax, Retail Demo, Smart Card, and Remote Registry services.
- **Taskbar Cleaner**: Disables "News and Interests" widget (the weather icon that eats RAM).
- **Silence**: Disables "Windows Tips", "Contextual Suggestions", and "Meet Now".

### ✅ User Safety
- **Auto-Restore Point**: Creates a System Restore point automatically before touching anything.
- **Network Safe**: Explicitly PRESERVES WiFi and Bluetooth drivers (needed for ELM327 OBD2 adapters).
- **Driver Safe**: Does not touch serial/USB drivers needed for Forscan/ADB.

## 🛠️ How to Run

1.  Download the repository (or just `ThinkPadDebloater.ps1` and `RunDebloater.bat`).
2.  Right-click `RunDebloater.bat` and select **Run as Administrator**.
    *   *(Or run the powershell script directly if you know how)*.
3.  Follow the Menu:
    *   **Option 1**: Create Restore Point (Do this first!)
    *   **Option 5**: **Run All Standard Tweaks** (Bloat, Telemetry, Visuals).
    *   **Option 7**: **Apply Final Extras** (Hibernation kill, OneDrive uninstall, Deep tweaks).

## ⚠️ Warning
This script is **AGGRESSIVE**. It is designed for a dedicated workshop/car laptop.
- The **Microsoft Store** will be gone.
- **OneDrive** will be gone.
- **Printing** will be disabled (Spooler service stopped).

## 📊 Results (ThinkPad 11E)
- **Idle CPU**: ~2%
- **RAM Usage**: ~3.4GB (Windows 10)
- **Processes**: ~121
