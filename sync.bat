:MAIN
@ECHO OFF
CALL :VARS
CALL :PREPARE
CALL :HEADER
CALL :MIRROR
CALL :FOOTER
CALL :COMPLETE
GOTO :EOF


:HEADER
CALL :LOG ----------------------------------------------
CALL :LOG  Synchronization started at %DATE% %TIME:~0,8% 
CALL :LOG ----------------------------------------------
GOTO :EOF


:VARS
FOR /F "tokens=1,2 delims==" %%I IN ('WMIC OS GET LocalDateTime /VALUE 2^>NUL') DO IF "%%I"=="LocalDateTime" SET DT=%%J
SET DATETIME=%DT:~6,2%.%DT:~4,2%.%DT:~0,4%

:: edit here
SET LOCAL="D:\"
SET REMOTE="\\192.168.1.1\Share\"
SET USER="DOMAIN\user"

SET FLAGS="/MIR /S /XO /XN /COPY:DAT /DCOPY:T /B /R:5 /W:5 /NP /NS /NC /NFL /NJH /NJS"
SET LOG="%~dp0logs\%DATETIME%.txt"
SET TMP="%~dp0logs\%DATETIME%.tmp"

SET "TEE=wtee.exe -a %TMP%"
GOTO :EOF


:PREPARE
DEL %TMP% 2>NUL
DEL %LOG% 2>NUL
NET USE %REMOTE:~1,-2% /user:%USER:"=% 1>NUL
GOTO :EOF


:MIRROR
CALL :MEASURE
SET START=%SECONDS%

:: edit here
CALL :SYNC "Photo"
CALL :SYNC "iMusic\Music" "Music"
CALL :SYNC "Work" "Work" ".git .svn $tf .idea obj bin Debug Release"

CALL :MEASURE
SET STOP=%SECONDS%

CALL :ELAPSED
GOTO :EOF


:FOOTER
CALL :LOG
CALL :LOG -----------------------------------------------
CALL :LOG  Synchronization finished at %DATE% %TIME:~0,8%
CALL :LOG  Elapsed time is %ELAPSED%
CALL :LOG -----------------------------------------------
GOTO :EOF


:COMPLETE
CMD /U /C TYPE %TMP%>%LOG%
DEL %TMP% 2>NUL
GOTO :EOF


:LOG
IF "%*"=="" (
	@ECHO. | %TEE%
) ELSE (
	@ECHO %* | %TEE%
)
GOTO :EOF


:MEASURE
FOR /F "skip=1 tokens=1-6" %%A IN ('WMIC PATH Win32_LocalTime GET Day^,Hour^,Minute^,Second /FORMAT:table ^| findstr /r "."') DO (
	SET D=%%A
	SET H=%%B
	SET M=%%C
	SET S=%%D
)
SET /A SECONDS=%D%*86400+%H%*3600+%M%*60+%S%
GOTO :EOF


:SYNC
SET "SRC=%LOCAL:"=%%~1"
IF "%~2"=="" (SET "DST=%REMOTE:"=%%~1") ELSE (SET "DST=%REMOTE:"=%%~2")
IF "%~3"=="" (SET "EXCLUDE=") ELSE (SET "EXCLUDE=/XD %~3")

CALL :LOG
CALL :LOG From: %SRC%
CALL :LOG To:   %DST%

ROBOCOPY "%SRC%" "%DST%" %FLAGS:"=% %EXCLUDE% | %TEE%
GOTO :EOF

:ELAPSED
SET /A H=(%STOP%-%START%)/3600
SET /A M=(%STOP%-%START%)/60-(H*3600)
SET /A S=(%STOP%-%START%)-(H*3600+M*60)

IF %H% LSS 10 SET H=0%H%
IF %M% LSS 10 SET M=0%M%
IF %S% LSS 10 SET S=0%S%

SET ELAPSED=%H%:%M%:%S%
GOTO :EOF