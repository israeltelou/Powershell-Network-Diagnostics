# PowerShell Network Diagnostics & Security Tool

A lightweight, Windows GUI-based network diagnostic tool built with PowerShell. Designed for system administrators and cybersecurity analysts to perform quick port scans and IP geolocation lookups.

## Features
- **TCP Port Scanner**: Fast asynchronous port testing on single target hosts or IP addresses.
- **IP Geolocation**: Query public IP addresses to retrieve ISP, Country, City, and ASN metadata via REST API.
- **Graphical User Interface**: Built-in Windows Forms UI for ease of use without complex CLI syntax.

## Requirements
- Windows OS (Windows 10/11, Windows Server 2016+)
- PowerShell 5.1 or later
- Internet access (for IP Geolocation feature)

## Usage
1. Clone this repository or download `NetworkDiagnostics.ps1`.
2. Open PowerShell as Administrator (optional, required for restricted networks).
3. Execute the script:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
   .\NetworkDiagnostics.ps1
