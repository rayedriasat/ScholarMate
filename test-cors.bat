@echo off
echo Testing CORS headers from Render...
curl -I -X OPTIONS https://scholarmate-fc1r.onrender.com/api/health ^
  -H "Origin: https://scholar-mate-nine.vercel.app" ^
  -H "Access-Control-Request-Method: GET"
