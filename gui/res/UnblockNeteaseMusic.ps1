Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$exePath = Join-Path $scriptDir "unblockneteasemusic.exe"
$certPath = Join-Path $scriptDir "ca.crt"
$cfgPath = Join-Path $scriptDir "config.json"
$exeUrl = "https://github.com/UnblockNeteaseMusic/server/releases/download/v0.28.0/unblockneteasemusic-win-x64.exe"
$exeSize = 37902453  # 预估大小

# 默认配置
$defaultCfg = @{
    sources=@("kuwo","kugou","migu","bilibili"); port=8080
    enableFlac=$false; enableLocalVip=$false; blockAds=$false
    selectMaxBr=$false; minBr=0; searchAlbum=$false; followSourceOrder=$false
    strict=$false; proxyUrl=""; forceHost=""; endpoint=""; cnrelay=""
    neteaseCookie=""; qqCookie=""; miguCookie=""; jooxCookie=""; youtubeKey=""
    logLevel="info"; noCache=$false
}
$cfg = $defaultCfg
if (Test-Path $cfgPath) {
    try { $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json } catch {}
}

$needDownload = -not (Test-Path $exePath)

# 图标
$iconBase64 = "AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAABILAAASCwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAgIAQZmZmYExMTKBMTEzQTExM0ExMTKBmZmZggICAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGZmZmBMTEzwb29v/5ubm/+srKz/rKys/5ubm/9vb2//TExM8GZmZmAAAAAAAAAAAAAAAAAAAAAAAAAAAABMTEyga2tr/6urq//IyMj/0NDQ/9DQ0P/IyMj/q6ur/2tra/9MTEygAAAAAAAAAAAAAAAAAAAAAExMTKB2dnb/wcHB/9DQ0P/Q0ND/0NDQ/9DQ0P/Q0ND/wcHB/3Z2dv9MTEygAAAAAAAAAAAAAAAAAAAAAExMTNCenp7/0NDQ/9DQ0P+AgID/UlJS/1JSUv+AgID/0NDQ/56env9MTEzQAAAAAAAAAAAAAAAAAAAAAExMTNCurq7/0NDQ/6ampv8wMDD/AAAA/wAAAP8wMDD/pqam/66urv9MTEzQAAAAAAAAAAAAAAAAAAAAAExMTNCurq7/0NDQ/6ampv8wMDD/AAAA/wAAAP8wMDD/pqam/66urv9MTEzQAAAAAAAAAAAAAAAAAAAAAExMTNCenp7/0NDQ/9DQ0P+AgID/QEBA/0BAQP+AgID/0NDQ/56env9MTEzQAAAAAAAAAAAAAAAAAAAAAExMTKB2dnb/wcHB/9DQ0P/Q0ND/0NDQ/9DQ0P/Q0ND/wcHB/3Z2dv9MTEygAAAAAAAAAAAAAAAAAAAAAAAAAACATEyga2tr/6urq//IyMj/0NDQ/9DQ0P/IyMj/q6ur/2tra/9MTEqgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGZmZmBMTEzwb29v/5ubm/+srKz/rKys/5ubm/9vb2//TExM8GZmZmAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAgIAQZmZmYExMTKBMTEzQTExM0ExMTKBmZmZggICAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//8AAP5/AAD8PwAA+B8AAPgfAADwDwAA8A8AAPAPAADwDwAA8A8AAPgfAAD4HwAA/D8AAP5/AAD//wAA//8AAA=="
$iconBytes = [Convert]::FromBase64String($iconBase64)
$iconStream = New-Object IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
$icon = New-Object System.Drawing.Icon($iconStream)

# 主窗口
$form = New-Object System.Windows.Forms.Form
$form.Text = "UnblockNeteaseMusic"
$form.Size = New-Object System.Drawing.Size(280, 200)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::White
$form.Icon = $icon

# 状态
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(20, 20)
$lblStatus.Font = New-Object System.Drawing.Font("Microsoft YaHei", 14)
$lblStatus.AutoSize = $true
if ($needDownload) {
    $lblStatus.Text = "首次使用"
    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(200, 120, 0)
} else {
    $lblStatus.Text = "已停止"
    $lblStatus.ForeColor = [System.Drawing.Color]::Gray
}
$form.Controls.Add($lblStatus)

# 端口信息
$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Location = New-Object System.Drawing.Point(20, 55)
$lblInfo.AutoSize = $true
$lblInfo.ForeColor = [System.Drawing.Color]::DarkGray
if ($needDownload) {
    $lblInfo.Text = "点击启动将下载核心程序 (~37MB)"
} else {
    $lblInfo.Text = "代理 127.0.0.1:$($cfg.port)"
}
$form.Controls.Add($lblInfo)

# 音源信息
$srcText = if ($cfg.sources -is [array]) { $cfg.sources -join ', ' } else { $cfg.sources }
$lblSrc = New-Object System.Windows.Forms.Label
$lblSrc.Text = "音源: $srcText"
$lblSrc.Location = New-Object System.Drawing.Point(20, 75)
$lblSrc.AutoSize = $true
$lblSrc.ForeColor = [System.Drawing.Color]::DarkGray
$form.Controls.Add($lblSrc)

# 进度条
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 108)
$progressBar.Size = New-Object System.Drawing.Size(230, 8)
$progressBar.Style = "Continuous"
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

# 按钮
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = if ($needDownload) { "下载并启动" } else { "启动" }
$btnStart.Location = New-Object System.Drawing.Point(20, 120)
$btnStart.Size = New-Object System.Drawing.Size(110, 35)
$btnStart.FlatStyle = "Flat"
$btnStart.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$btnStart.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($btnStart)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "停止"
$btnStop.Location = New-Object System.Drawing.Point(140, 120)
$btnStop.Size = New-Object System.Drawing.Size(110, 35)
$btnStop.FlatStyle = "Flat"
$btnStop.Enabled = $false
$form.Controls.Add($btnStop)

function Install-Cert {
    & certutil -addstore -f Root $certPath 2>&1 | Out-Null
    return $true
}

function Start-Proxy {
    $p = $cfg.port
    $src = if ($cfg.sources -is [array]) { $cfg.sources -join ' ' } else { $cfg.sources }
    $arguments = "-p ${p}:$([int]$p + 363) -o $src"

    if ($cfg.proxyUrl) { $arguments += " -u `"$($cfg.proxyUrl)`"" }
    if ($cfg.forceHost) { $arguments += " -f `"$($cfg.forceHost)`"" }
    if ($cfg.endpoint) { $arguments += " -e `"$($cfg.endpoint)`"" }
    if ($cfg.cnrelay) { $arguments += " -c `"$($cfg.cnrelay)`"" }
    if ($cfg.strict) { $arguments += " -s" }

    if ($cfg.enableFlac) { $env:ENABLE_FLAC = "true" }
    if ($cfg.enableLocalVip) { $env:ENABLE_LOCAL_VIP = "true" }
    if ($cfg.blockAds) { $env:BLOCK_ADS = "true" }
    if ($cfg.selectMaxBr) { $env:SELECT_MAX_BR = "true" }
    if ($cfg.minBr -gt 0) { $env:MIN_BR = $cfg.minBr }
    if ($cfg.searchAlbum) { $env:SEARCH_ALBUM = "true" }
    if ($cfg.followSourceOrder) { $env:FOLLOW_SOURCE_ORDER = "true" }
    if ($cfg.noCache) { $env:NO_CACHE = "true" }
    if ($cfg.logLevel) { $env:LOG_LEVEL = $cfg.logLevel }
    if ($cfg.neteaseCookie) { $env:NETEASE_COOKIE = $cfg.neteaseCookie }
    if ($cfg.qqCookie) { $env:QQ_COOKIE = $cfg.qqCookie }
    if ($cfg.miguCookie) { $env:MIGU_COOKIE = $cfg.miguCookie }
    if ($cfg.jooxCookie) { $env:JOOX_COOKIE = $cfg.jooxCookie }
    if ($cfg.youtubeKey) { $env:YOUTUBE_KEY = $cfg.youtubeKey }

    try {
        $script:process = Start-Process -FilePath $exePath -ArgumentList $arguments -PassThru -WindowStyle Hidden
        $lblStatus.Text = "运行中"
        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 0)
        $lblInfo.Text = "代理 127.0.0.1:$($cfg.port)"
        $progressBar.Visible = $false
        $btnStart.Text = "启动"
        $btnStart.Enabled = $false
        $btnStop.Enabled = $true
    } catch {
        $lblStatus.Text = "启动失败"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
    }
}

# 下载进度定时器
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 300
$timer.Add_Tick({
    if (Test-Path $exePath) {
        $size = (Get-Item $exePath).Length
        $percent = [math]::Min(100, [math]::Round($size / $exeSize * 100))
        $progressBar.Value = $percent
        $lblStatus.Text = "下载中 $percent%"

        if ($size -ge $exeSize - 1000) {
            $timer.Stop()
            $progressBar.Value = 100
            Start-Sleep -Milliseconds 200
            Start-Proxy
        }
    }
})

$btnStart.Add_Click({
    if (-not (Install-Cert)) { return }

    if (Test-Path $exePath) {
        Start-Proxy
        return
    }

    # 后台下载
    $lblStatus.Text = "下载中 0%"
    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 200)
    $lblInfo.Text = "正在从 GitHub 下载..."
    $progressBar.Value = 0
    $progressBar.Visible = $true
    $btnStart.Enabled = $false

    Start-Process -WindowStyle Hidden -FilePath "powershell" -ArgumentList "-Command", "Invoke-WebRequest -Uri '$exeUrl' -OutFile '$exePath' -UseBasicParsing"
    $timer.Start()
})

$btnStop.Add_Click({
    if ($script:process) { try { $script:process.Kill() } catch {} }
    Get-Process -Name "unblockneteasemusic" -ErrorAction SilentlyContinue | Stop-Process -Force
    $lblStatus.Text = "已停止"
    $lblStatus.ForeColor = [System.Drawing.Color]::Gray
    $btnStart.Enabled = $true
    $btnStop.Enabled = $false
})

$form.Add_FormClosing({
    $timer.Stop()
    if ($script:process) { try { $script:process.Kill() } catch {} }
    Get-Process -Name "unblockneteasemusic" -ErrorAction SilentlyContinue | Stop-Process -Force
})

$form.ShowDialog()
