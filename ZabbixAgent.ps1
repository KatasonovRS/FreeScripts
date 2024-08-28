# Запуск коммандой
# Set-ExecutionPolicy Bypass -Force ; powershell   -File "\\192.168.0.22\Obmen\TEMP\zabbix.ps1"


# Укажите путь к вашему MSI-файлу Zabbix
$zabbixMsiPath = '\\192.168.0.22\Obmen\TEMP\zabbix_agent-7.0.3-windows-amd64-openssl.msi'

# Укажите IP-адрес вашего Zabbix-сервера
$zabbixServerIP = '192.168.100.75'

# Укажите IP-адрес для параметра ServerActive
$zabbixServerActiveIP = '192.168.100.75'

# Проверка наличия файла MSI
if (-Not (Test-Path $zabbixMsiPath)) {
    Write-Host "Ошибка: MSI-файл не найден по пути $zabbixMsiPath."
    exit 1
}

# Удаление старого Zabbix Agent, если он установлен
$existingZabbixAgent = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE 'Zabbix Agent%'" -ErrorAction SilentlyContinue
if ($existingZabbixAgent) {
    Write-Host "Найдена установленная версия Zabbix Agent. Удаление..."
    $existingZabbixAgent.Uninstall()
    Start-Sleep -Seconds 10  # Ожидание завершения удаления
} else {
    Write-Host "Старый Zabbix Agent не найден."
}

# Параметры для установки Zabbix Agent через MSI
$msiArguments = @(
    '/i', "`"$zabbixMsiPath`"",          # путь к MSI
    "SERVER=$zabbixServerIP",            # IP-адрес Zabbix-сервера
    "HOSTNAME=$(hostname)",              # Имя хоста будет текущим именем машины
    "ServerActive=$zabbixServerActiveIP", # Установка ServerActive
    '/quiet', '/norestart'               # Тихая установка без перезагрузки
)

# Установка Zabbix Agent
Write-Host "Начало установки Zabbix Agent..."
Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList $msiArguments -Wait

# Проверка успешной установки службы Zabbix Agent
$service = Get-Service -Name "Zabbix Agent" -ErrorAction SilentlyContinue
if ($service -and $service.Status -ne 'Stopped') {
    Write-Host "Zabbix Agent успешно установлен и настроен."
} else {
    Write-Host "Ошибка при установке Zabbix Agent."
}

# Настройка правил Windows Firewall для Zabbix Agent
Write-Host "Настройка правил Windows Firewall для Zabbix Agent..."
$firewallRuleName = "Zabbix Agent"
$existingRule = Get-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Host "Правило для Zabbix Agent уже существует."
} else {
    New-NetFirewallRule -DisplayName $firewallRuleName -Direction Inbound -Protocol TCP -LocalPort 10050 -Action Allow -Profile Any
    Write-Host "Правило Windows Firewall для Zabbix Agent добавлено."
}

Write-Host "Скрипт завершен."
