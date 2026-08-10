@echo off
echo Testing /chat endpoint with correct API key...
curl.exe -i -X POST https://k4-day12-2a202601238-daotrunghieu.onrender.com/chat ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer rJ_S1N5HC142tREVu0HhAACU6GisVnJPlSouLzOy3Hg" ^
  -H "X-Client-Id: sv-test" ^
  -d "{\"message\":\"Deploy la gi?\"}"
echo.
pause
