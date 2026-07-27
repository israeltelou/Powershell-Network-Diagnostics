<#
.SYNOPSIS
    GUI Network Diagnostic Tool - Port Scanner & IP Geolocation.
.DESCRIPTION
    A PowerShell tool providing a graphical user interface for scanning open TCP ports
    and performing IP geolocation lookup via public REST API.
.AUTHOR
    Israel
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Main Window Setup ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Network Diagnostics & Scanner Tool"
$form.Size = New-Object System.Drawing.Size(550, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# --- Tab Control ---
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Dock = "Fill"

# ==========================================
# TAB 1: Port Scanner
# ==========================================
$tabPortScanner = New-Object System.Windows.Forms.TabPage
$tabPortScanner.Text = "Port Scanner"

$lblTarget = New-Object System.Windows.Forms.Label
$lblTarget.Location = New-Object System.Drawing.Point(20, 20)
$lblTarget.Size = New-Object System.Drawing.Size(120, 20)
$lblTarget.Text = "Target IP / Host:"

$txtTarget = New-Object System.Windows.Forms.TextBox
$txtTarget.Location = New-Object System.Drawing.Point(140, 18)
$txtTarget.Size = New-Object System.Drawing.Size(180, 20)
$txtTarget.Text = "127.0.0.1"

$lblPorts = New-Object System.Windows.Forms.Label
$lblPorts.Location = New-Object System.Drawing.Point(20, 50)
$lblPorts.Size = New-Object System.Drawing.Size(120, 20)
$lblPorts.Text = "Ports (e.g. 80,443,22):"

$txtPorts = New-Object System.Windows.Forms.TextBox
$txtPorts.Location = New-Object System.Drawing.Point(140, 48)
$txtPorts.Size = New-Object System.Drawing.Size(180, 20)
$txtPorts.Text = "21,22,80,443,3389,8080"

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Location = New-Object System.Drawing.Point(340, 18)
$btnScan.Size = New-Object System.Drawing.Size(160, 50)
$btnScan.Text = "Start Scan"
$btnScan.BackColor = [System.Drawing.Color]::LightBlue

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 90)
$txtLog.Size = New-Object System.Drawing.Size(480, 420)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)

$tabPortScanner.Controls.AddRange(@($lblTarget, $txtTarget, $lblPorts, $txtPorts, $btnScan, $txtLog))

# ==========================================
# TAB 2: IP Geolocation
# ==========================================
$tabGeo = New-Object System.Windows.Forms.TabPage
$tabGeo.Text = "IP Geolocation"

$lblGeoIP = New-Object System.Windows.Forms.Label
$lblGeoIP.Location = New-Object System.Drawing.Point(20, 20)
$lblGeoIP.Size = New-Object System.Drawing.Size(120, 20)
$lblGeoIP.Text = "Public IP Address:"

$txtGeoIP = New-Object System.Windows.Forms.TextBox
$txtGeoIP.Location = New-Object System.Drawing.Point(140, 18)
$txtGeoIP.Size = New-Object System.Drawing.Size(180, 20)
$txtGeoIP.Text = "8.8.8.8"

$btnGeo = New-Object System.Windows.Forms.Button
$btnGeo.Location = New-Object System.Drawing.Point(340, 16)
$btnGeo.Size = New-Object System.Drawing.Size(160, 25)
$btnGeo.Text = "Lookup Geolocation"

$txtGeoResult = New-Object System.Windows.Forms.TextBox
$txtGeoResult.Location = New-Object System.Drawing.Point(20, 60)
$txtGeoResult.Size = New-Object System.Drawing.Size(480, 450)
$txtGeoResult.Multiline = $true
$txtGeoResult.ScrollBars = "Vertical"
$txtGeoResult.ReadOnly = $true
$txtGeoResult.Font = New-Object System.Drawing.Font("Consolas", 10)

$tabGeo.Controls.AddRange(@($lblGeoIP, $txtGeoIP, $btnGeo, $txtGeoResult))

$tabControl.TabPages.Add($tabPortScanner)
$tabControl.TabPages.Add($tabGeo)
$form.Controls.Add($tabControl)

# ==========================================
# LOGIC & EVENTS
# ==========================================

# Port Scanning Action
$btnScan.Add_Click({
    $txtLog.Clear()
    $target = $txtTarget.Text.Trim()
    $ports = $txtPorts.Text.Split(',') | ForEach-Object { $_.Trim() }

    if ([string]::IsNullOrWhiteSpace($target)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a valid target IP or hostname.", "Error")
        return
    }

    $txtLog.AppendText(" Starting scan on target: $target`r`n")
    $txtLog.AppendText("==========================================`r`n")

    # Initialisation de la variable pour éviter le crash [ref]
    $port = 0

    foreach ($portStr in $ports) {
        if ([int]::TryParse($portStr, [ref]$port)) {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            try {
                $asyncResult = $tcpClient.BeginConnect($target, $port, $null, $null)
                $waitHandle = $asyncResult.AsyncWaitHandle.WaitOne(800, $false)

                if (-not $waitHandle) {
                    $tcpClient.Close()
                    $txtLog.AppendText("[-] Port $port : CLOSED / TIMEOUT`r`n")
                } else {
                    $tcpClient.EndConnect($asyncResult)
                    $txtLog.AppendText("[+] Port $port : OPEN`r`n")
                    $tcpClient.Close()
                }
            } catch {
                $txtLog.AppendText("[-] Port $port : CLOSED`r`n")
            } finally {
                $tcpClient.Dispose()
            }
        }
    }
    $txtLog.AppendText("==========================================`r`n")
    $txtLog.AppendText(" Scan completed.`r`n")
})

# IP Geolocation Action
$btnGeo.Add_Click({
    $txtGeoResult.Clear()
    $ip = $txtGeoIP.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($ip)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a valid IP address.", "Error")
        return
    }

    $txtGeoResult.AppendText(" Querying geolocation data for $ip...`r`n`r`n")

    # Forcer TLS 1.2 pour la requête HTTP
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    try {
        $response = Invoke-RestMethod -Uri "http://ip-api.com/json/$ip" -Method Get -TimeoutSec 5
        if ($response.status -eq "success") {
            $txtGeoResult.AppendText("IP Address  : $($response.query)`r`n")
            $txtGeoResult.AppendText("Country     : $($response.country) ($($response.countryCode))`r`n")
            $txtGeoResult.AppendText("Region      : $($response.regionName)`r`n")
            $txtGeoResult.AppendText("City        : $($response.city)`r`n")
            $txtGeoResult.AppendText("ISP         : $($response.isp)`r`n")
            $txtGeoResult.AppendText("Org         : $($response.org)`r`n")
            $txtGeoResult.AppendText("Lat / Lon   : $($response.lat), $($response.lon)`r`n")
            $txtGeoResult.AppendText("Timezone    : $($response.timezone)`r`n")
        } else {
            $txtGeoResult.AppendText("[-] Error retrieving data: $($response.message)`r`n")
        }
    } catch {
        $txtGeoResult.AppendText("[-] Request failed (Check Internet/DNS connectivity): $_`r`n")
    }
})

# Run Application
[System.Windows.Forms.Application]::Run($form)
