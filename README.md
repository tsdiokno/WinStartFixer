# WinStartFixer 🚀

### Problem
Windows Search and the Start Menu often fail to index programs installed on secondary drives (D:, E:, etc.) or portable applications. This leaves users digging through folders just to launch a tool they've already installed.

Manually creating shortcuts for dozens of apps is tedious. Even when you do, you often end up with messy names like `Launcher_v2.final (x64)`, broken icons, or shortcuts that accidentally point to the `uninstaller.exe` instead of the actual game or app.

### Solution
**WinStartFixer** is a lightweight PowerShell utility that audits your installed software across all drives. It identifies what's missing from your Start Menu, cleans up messy versioning nomenclature, and batch-generates proper shortcuts with correct icons and working directories in a single action.

---

## Features
* 🔍 **Deep Scan:** Audits Registry, 64-bit, and 32-bit install paths.
* 🛠️ **Path Fallback:** Finds folders even if the Registry entry is incomplete by analyzing uninstall strings and icon paths.
* 🧹 **Name Cleaning:** Automatically removes junk like `(User)`, `v1.0.2`, and `2024` from shortcut names.
* 🛡️ **Smart Filtering:** Ignores uninstallers, setup files, and helpers to ensure the shortcut actually opens the app.
* 🎨 **Icon Support:** Preserves original app icons for a native Windows look.
* 📊 **Status Tracking:** Clearly shows what is already in your Start Menu and what is missing.

---

## How to Use
1. **Download** `FixStartMenu.ps1`.
2. **Open PowerShell as Administrator.**
3. **Run the script:**
   ```powershell
   .\FixStartMenu.ps1
   ```
   (Note: You may need to run `Set-ExecutionPolicy RemoteSigned -Scope Process` to allow the script to run.)
4. Select IDs: Enter the numbers of the programs you want to fix (e.g., 1, 4, 12) and hit Enter.

## License
Licensed under the Mozilla Public License 2.0.

## AI Disclosure
This application was 100% vibe-coded with AI (Google Gemini).
