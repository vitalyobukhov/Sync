@ECHO OFF
SETLOCAL EnableDelayedExpansion

:MAIN
	CALL :VARS
	CALL :PREPARE
	CALL :HEADER
	CALL :CLEAN
	CALL :MIRROR
	CALL :FOOTER
	CALL :COMPLETE
GOTO :EOF


:VARS
	FOR /F "tokens=1,2 delims==" %%I IN ('WMIC OS GET LocalDateTime /VALUE 2^>NUL') DO IF "%%I"=="LocalDateTime" SET DT=%%J
	SET DATETIME=%DT:~6,2%.%DT:~4,2%.%DT:~0,4%

	:: EDIT HERE
	SET LOCAL="D:\"
	SET REMOTE="\\ROUTER\Share\"
	REM USER="WORKGROUP\user"

	SET FLAGS="/MIR /S /XO /XN /COPY:DAT /DCOPY:T /R:5 /W:5 /NP /NS /NC /NFL /NJH /NJS"
	SET "LOGS=%~dp0logs"
	SET LOG="%LOGS%\%DATETIME%.txt"
	SET TMP="%LOGS%\%DATETIME%.tmp"
	SET LOGLIFE=1

	SET "TEE=wtee.exe -a %TMP%"
GOTO :EOF


:PREPARE
	DEL %TMP% 2>NUL
	DEL %LOG% 2>NUL
	
	REM NET USE %REMOTE:~1,-2% /user:%USER:"=% * 1>NUL
GOTO :EOF


:HEADER
	CALL :LOG ----------------------------------------------
	CALL :LOG  Synchronization started at %DATE% %TIME:~0,8% 
	CALL :LOG ----------------------------------------------
GOTO :EOF


:MIRROR
	CALL :MEASURE
	SET START=%SECONDS%

	:: EDIT HERE
	CALL :SYNC "Demo"
	CALL :SYNC "Docs" "My\Docs"
	CALL :SYNC "Work" "Work" ".git .svn $tf .idea .settings obj bin Debug Release gen out"

	CALL :MEASURE
	SET STOP=%SECONDS%

	CALL :ELAPSED
GOTO :EOF


:CLEAN
	SET DELETED=0

	CALL :DMY %DATETIME%
	SET CM=%M%
	SET CY=%Y%

	FOR /F %%I IN ('DIR "%LOGS%\*.txt" /B 2^>NUL') DO (
		SET	"FILENAME=%LOGS%\%%I"
		
		CALL :DMY %%I
		
		SET /A DY=!CY!-!Y!
		SET /A DM=!CM!-!M!
		SET /A D=!DY!*12+!DM!
		
		IF !D! GTR %LOGLIFE% (
			DEL /F "!FILENAME!"
			IF !DELETED! EQU 0 CALL :LOG
			CALL :LOG Deleted: !FILENAME!
			SET /A DELETED=!DELETED!+1
		)
	)
	
	IF !DELETED! GTR 0 (
		CALL :LOG Total: !DELETED!
	)
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


:DMY
	FOR /F "delims=. tokens=1-3" %%I IN ("%1") DO (
		CALL :INT %%I
		SET D=!INT!
		CALL :INT %%J
		SET M=!INT!
		CALL :INT %%K
		SET Y=!INT!
	)
GOTO :EOF


:INT
	FOR /F "tokens=* delims=0" %%I IN ("%1") DO SET INT=%%I
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