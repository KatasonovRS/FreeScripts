# FreeScripts
**Скрипты для автоматизации IT задач.**

**ZabbixAgent.ps1** - Выполняется от имени администратора коммандой в powershell "powershell.exe -ExecutionPolicy Bypass -File "\\SMB Адресс расшаренного скрипта zabbix.ps1"".
**Особенности:**
- Внешний адресс нахождения скрипта в шаре \\192.168.0.22\Obmen\TEMP\zabbix.ps1.
- Внешнее нахождение клиента в шаре "$zabbixMsiPath = '\\192.168.0.22\Obmen\TEMP\zabbix_agent-7.0.3-windows-amd64-openssl.msi'".
- Указание Адреса сервера $zabbixServerIP = "'192.168.100.75'" и "$zabbixServerActiveIP = '192.168.100.75'".
- Проверка на уже установленный клиент Zabbix и удаление ( Очень хорошо при обновлении на новые версии ).
- Добавление открытия порта в  FireWall / Брандмауэр.

**ZabbixServerDocker.sh**
Скрипт подготовлен для выполнения в Ubuntu Server. (и довольно легко адаптируеться под любой другой GNU/Linux ).
Веб панель будет доступна по IP:8080.
**Особенности:**
- Автоустановка необходимого софта "cron htop mc nload screenfetch net-tools traceroute docker.io".
- Остановка и удаление всех контейнеров сетей и мусора.
- Запуск MariaDB ( База данных ).
- Настройка базы данных и конвертация всех таблиц в UTF8.
- Запуск Zabbix-Server ( Сам сервер Zabbix ).
- Запуск Zabbix-Frontend ( Веб панель ).
- Запуск Zabbix-Agent ( Агент мониторинга ).
- Кастомное место сохранения базы данных при удалении всего база сохраняется а также всегда доступна для подключения по удаленке по порту 3306 "-v mariadb_data:/var/lib/mysql \".
- Благодаря этому скрипту и автозагрузке у вас при перезагрузки сервера всегда будет самая последняя и актуальная версия Zabbix.
