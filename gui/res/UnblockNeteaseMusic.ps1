Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$exePath = Join-Path $scriptDir "unblockneteasemusic.exe"
$certPath = Join-Path $scriptDir "ca.crt"
$cfgPath = Join-Path $scriptDir "config.json"
$exeUrl = "https://github.com/UnblockNeteaseMusic/server/releases/latest/download/unblockneteasemusic-win-x64.exe"
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

# 图标 (官方logo)
$iconBase64 = "AAABAAEAEBAAAAEAIADzAgAAFgAAAIlQTkcNChoKAAAADUlIRFIAAAAQAAAAEAgGAAAAH/P/YQAAAAFzUkdCAK7OHOkAAAAEZ0FNQQAAsY8L/GEFAAAACXBIWXMAAA7DAAAOwwHHb6hkAAACiElEQVQ4T7WPW0hTcRzHR48VmU7nznacCzfd7Ww7usvZdNlMnZcjODanWD2sHoIwegmpHnpSMXzwLZO0hyRiZl6ixh6EIRIFUl5AJ4mWIkTeZmUXd7Z9QylhC3yqD/xefv//5wM/Hu8/c6RdlkYmLw/FKzye0atIZx8p+Z0+JX9yhBLuDOmICZ9WeKePEpw9J0s7kezwutmCo+Ml6muPVZmBPnnqxnN1Bka1AgQoAfw6AkGDGONGEgGawIBGsDqsJwf8xYqGfXnIoZMOlukfbtfmg3PSmLXnIkCL0a9MxxMFH8NUJka0QjzTEwgyUsyXa7DrYbDuNmPQLsvh9dmpvDYmR7ZWqQnATSNepcB3VoPFUiWCJgle0GK8Pi3HIktjs47Bl3oLwnUMcMGGuRq64+CMbyzlQ4MJ3K2L4LylQL0ZkVod1p3GeNhjxWePBVtuM7bqGHxtsGKnntmertQ1HwQ+WUXdaG1CdKAXsTE/Ije9iFTkYq2Kim24mX0x7LFgw2XCdjUFfwHZdiDvETII2nH7EriuVsTevgTX0QzOIcdKiTy+5jJh023GSoUGs9ZsLJlJjKgymhICM7bsG/Dawd1r/T1tiDYW4YNNGl+w5yFUdApTBhGmjWIsWyV4RQvPJwTmyxRX4KIQu94IrqsF0f77iDYWYtkmjb3JJ/bFaROJkDkLHwuzMU6LahICcw4FsV6t9oFVAVdrEbnMIlqjwfIZWXzSIMaMicR7iwQhJgtBWtRzV5KSmhD4w7tytSvsyFuAkwJc+XuB2KyRxGqhBBMG8cxTrbAi2fmLTl3KyZVKVecPpz6661Ds3f5zTE+0aDN5x5L/HspUqapoqTin50Eu35j89s/4BThFRjat+gcMAAAAAElFTkSuQmCC"
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
$btnStop.BackColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
$btnStop.ForeColor = [System.Drawing.Color]::White
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
        $btnStart.Text = "运行中"
        $btnStart.Enabled = $false
        $btnStart.BackColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
        $btnStop.Enabled = $true
        $btnStop.BackColor = [System.Drawing.Color]::FromArgb(200, 60, 60)
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
    $btnStart.Text = "启动"
    $btnStart.Enabled = $true
    $btnStart.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $btnStop.Enabled = $false
    $btnStop.BackColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
})

$form.Add_FormClosing({
    $timer.Stop()
    if ($script:process) { try { $script:process.Kill() } catch {} }
    Get-Process -Name "unblockneteasemusic" -ErrorAction SilentlyContinue | Stop-Process -Force
})

$form.ShowDialog()
