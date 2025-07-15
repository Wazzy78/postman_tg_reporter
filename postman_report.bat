@echo off
setlocal enabledelayedexpansion


set "BOT_TOKEN=7964389839:AAHGNkOrJ6W_Krx-VHMpXIit0IjKhU9prCU"
set "CHAT_ID=5738877781"


set "JQ=C:\Program Files\jq\jq.exe"

newman run "C:\Users\User\auction-tests.json" -r cli,json --reporter-json-export result.json

if not exist result.json (
    echo ❌ Error: result.json not found.
    pause
    exit /b
)


for /f %%i in ('"%JQ%" ".run.stats.requests.total" result.json') do set TOTAL=%%i
for /f %%i in ('"%JQ%" ".run.stats.requests.completed" result.json') do set COMPLETED=%%i
for /f %%i in ('"%JQ%" ".run.failures | length" result.json') do set FAILURES=%%i
set /a PASSED=TOTAL - FAILURES


echo. > failed_details.txt
for /f "delims=" %%A in ('"%JQ%" -r ".run.failures[] | \"- \" + .source.name + \": ❌ Failed (Response Code: \" + (if .response.code then (.response.code|tostring) else \"undefined\") + \")\"" result.json') do (
    echo %%A>> failed_details.txt
)


set "MESSAGE=Test Results%%0A%%0ATotal Requests: %TOTAL%%%0ACompleted Requests: %COMPLETED%%%0ASuccessful Requests: %PASSED%%%0AFailed Requests: %FAILURES%%%0A"


for /f "usebackq delims=" %%L in (failed_details.txt) do set "MESSAGE=!MESSAGE!%%0A%%L"


echo 📡sending to telegram
curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
-d "chat_id=%CHAT_ID%" ^
-d "text=!MESSAGE!"

del failed_details.txt

echo Ready
pause
