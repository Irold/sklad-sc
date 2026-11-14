@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Склад-СЦ

where python >nul 2>nul
if errorlevel 1 (
  echo.
  echo Python не найден.
  echo Скачайте его с https://www.python.org/downloads/
  echo При установке поставьте галочку "Add python.exe to PATH".
  echo Потом снова запустите этот файл.
  echo.
  pause
  exit /b 1
)

if not exist ".venv\Scripts\python.exe" (
  echo Первый запуск: создаю окружение, это займёт минуту...
  python -m venv .venv
)
set PY=.venv\Scripts\python.exe

echo Устанавливаю зависимости...
"%PY%" -m pip install -q -r requirements.txt
if errorlevel 1 goto fail

echo Обновляю базу данных...
"%PY%" manage.py migrate
if errorlevel 1 goto fail

if not exist ".demo_loaded" (
  echo Создаю тестовые данные: 5000 деталей...
  "%PY%" manage.py seed_demo --parts 5000
  if errorlevel 1 goto fail
  echo ok> .demo_loaded
)

"%PY%" manage.py shell -c "from django.contrib.auth.models import User; User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', '', 'admin')"

echo.
echo ==================================================
echo   Откроется браузер: http://127.0.0.1:8000
echo   Вход: admin / admin
echo   Чтобы остановить, закройте это окно.
echo ==================================================
echo.
start "" cmd /c "timeout /t 4 >nul & start http://127.0.0.1:8000/admin/login/?next=/sklad/"
"%PY%" manage.py runserver
pause
exit /b 0

:fail
echo.
echo Что-то пошло не так. Сделайте скриншот этого окна и пришлите в чат.
pause
exit /b 1
