start "" "julia" --threads auto --color=yes --depwarn=no --project=@. -q -i -- "%~dp0..\bootstrap.jl" %*
timeout /t 13 /nobreak
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" "http://localhost:8001/"