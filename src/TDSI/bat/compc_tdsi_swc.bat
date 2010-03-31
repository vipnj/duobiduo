set filepath=%~dp0
set filepath=%filepath%..
call %filepath%\bat\compc-swc.bat
call %filepath%\bat\tdsi-swc.bat
pause