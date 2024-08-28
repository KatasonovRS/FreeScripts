Invoke-Command -ComputerName "TEST-123" -ScriptBlock {
#Службы необходимые вкл на пк
#Enable-PSRemoting -Force
#Start-Service WinRM



    # Укажите URL к вашему MSI-файлу Zabbix
    $zabbixMsiUrl = 'http://192.168.0.71:8181/zabbix_agent-7.0.3-windows-amd64-openssl.msi'

    # Локальный путь для сохранения загруженного MSI-файла
    $zabbixMsiPath = 'C:\Temp\zabbix_agent-7.0.3-windows-amd64-openssl.msi'

    # Укажите IP-адрес вашего Zabbix-сервера
    $zabbixServerIP = '192.168.100.75'

    # Укажите IP-адрес для параметра ServerActive
    $zabbixServerActiveIP = '192.168.100.75'

    # Создаем папку C:\Temp, если она не существует
    if (-Not (Test-Path "C:\Temp")) {
        New-Item -Path "C:\Temp" -ItemType Directory
    }

    # Загрузка MSI-файла через HTTP
    try {
        Invoke-WebRequest -Uri $zabbixMsiUrl -OutFile $zabbixMsiPath
        Write-Host "MSI-файл успешно загружен в $zabbixMsiPath."
    } catch {
        Write-Host "Ошибка: не удалось загрузить MSI-файл по URL $zabbixMsiUrl."
        exit 1
    }

    # Проверка наличия загруженного файла MSI
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
        '/i', "`"$zabbixMsiPath`"",          # путь к загруженному MSI
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
}
