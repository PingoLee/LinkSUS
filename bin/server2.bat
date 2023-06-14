start "C:\Program Files\Google\Chrome\Application\chrome.exe" "http://localhost:8001/"
julia --threads auto --color=yes --depwarn=no --project=@. -q -i -- "%~dp0..\bootstrap.jl" -s=true %*
pause 