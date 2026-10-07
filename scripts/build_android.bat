@echo off
cd /d "%~dp0\.."
where flutter >nul 2>&1
if errorlevel 1 (
  echo Flutter is missing from PATH. See START_HERE_URDU.md or README.md.
  exit /b 1
)
if not exist config.json if exist config.public.json copy /y config.public.json config.json >nul
if not exist config.json (
  echo Copy config.example.json to config.json and enter public configuration.
  exit /b 1
)
call flutter pub get
if errorlevel 1 exit /b 1
call flutter analyze
if errorlevel 1 exit /b 1
call flutter test
if errorlevel 1 exit /b 1
call flutter build apk --debug --dart-define-from-file=config.json
if errorlevel 1 exit /b 1
echo Built: build\app\outputs\flutter-apk\app-debug.apk
