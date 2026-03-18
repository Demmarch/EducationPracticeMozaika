@echo off
echo Deploying PostgreSQL libraries...

set POSTGRESQL_PATH=D:\Programs\PostgreSQL\bin

copy "%POSTGRESQL_PATH%\libpq.dll" %1
copy "%POSTGRESQL_PATH%\libintl-9.dll" %1
copy "%POSTGRESQL_PATH%\libiconv-2.dll" %1
copy "%POSTGRESQL_PATH%\libssl-3-x64.dll" %1
copy "%POSTGRESQL_PATH%\libcrypto-3-x64.dll" %1

echo Libraries copied successfully!