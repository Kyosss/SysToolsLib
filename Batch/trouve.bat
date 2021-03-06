@echo off
:##############################################################################
:#                                                                            #
:#  Filename:       trouve.bat                                                #
:#                                                                            #
:#  Description:    Find files containing a given string                      #
:#                                                                            #
:#  Notes:	    Uses a Windows port of the Unix find and grep commands.   #
:#                  Searches for a few known ports in the directories:        #
:#                  ezwinports.sourceforge.net  %~dp0%\ezWinPorts\Win64\bin   #
:#                  ezwinports.sourceforge.net  %~dp0%\ezWinPorts\Win32\bin   #
:#                  unxutils.sourceforge.net    %~dp0%\UnxUtils\usr\local\wbin#
:#                  gnuwin32.sourceforge.net    %~dp0%\GnuWin32\bin           #
:#                  mingw.sourceforge.net       %~d0%\MinGW\msys\1.0\bin      #
:#                                                                            #
:#  History:                                                                  #
:#   2010-05-04 JFL Changed the default to case-insensitive name matching.    #
:#                  Added options -j and -J.                                  #
:#                  Renamed option -in as -D.                                 #
:#   2010-10-29 JFL Dynamically detect the tools path.			      #
:#                  Added partial support for SUA Unix tools.                 #
:#                  Added options -r and changed the default to non-recursive.#
:#   2010-12-08 JFL Use %~f0 instead of "which %0".			      #
:#                  Added options -m and -s to allow testing both Unix finds. #
:#   2010-12-19 JFL Use routine condquote to quote find & grep if needed.     #
:#   2013-04-03 JFL First try ezWinPorts versions of find & grep, which are   #
:#                  much faster than the others. (Specially the 64-bits one)  #
:#   2013-04-04 JFL The ezWinPorts versions already end lines with crlf.      #
:#                  Made the -D optional before the directory name.           #
:#                  Added option -v.                                          #
:#   2013-04-05 JFL Added support for the gnuwin32 and mingw ports.           #
:#   2016-10-11 JFL Added options -d, -l, -L.                                 #
:#                                                                            #
:#         � Copyright 2016 Hewlett Packard Enterprise Development LP         #
:# Licensed under the Apache 2.0 license  www.apache.org/licenses/LICENSE-2.0 #
:##############################################################################

setlocal EnableExtensions EnableDelayedExpansion
set "VERSION=2016-10-11"
set "SCRIPT=%~nx0"
set "SCRIPT_DRIVE=%~d0"
set "SCRIPT_PATH=%~dp0" & set "SCRIPT_PATH=!SCRIPT_PATH:~0,-1!"
set "ARG0=%~f0"
set  ARGS=%*

set FUNCTION=rem
set RETURN=goto :eof
goto main

:# Quote file pathnames that require it. %1=Input variable. %2=Opt. output variable.
:condquote
%FUNCTION% condquote %1 %2
setlocal enableextensions
call set "P=%%%~1%%"
set "P=%P:"=%"
set RETVAR=%~2
if not defined RETVAR set RETVAR=%~1
for %%c in (" " "&" "(" ")" "@" "," ";" "[" "]" "{" "}" "=" "'" "+" "`" "~") do (
  :# Note: Cannot directly nest for loops, due to incorrect handling of /f in the inner loop.
  cmd /c "for /f "tokens=1,* delims=%%~c" %%a in (".%%P%%.") do @if not "%%b"=="" exit 1"
  if errorlevel 1 (
    set P="%P%"
    goto :condquote_ret
  )
)
:condquote_ret
endlocal & set "%RETVAR%=%P%"
%RETURN%

:# Search for a Windows port of Unix tools.
:# Search in the standard location, or underneath this script directory.
:# This is useful, because some of my VMs do dot have a copy of the tools,
:# but instead have the host's tools directory in their PATH.

:# Search for the ezwinport.sourceforge.net port of a Unix program.
:ezWinPorts %1=program. Returns variable %1 set to the exe full pathname.
:# Search in the standard location, or underneath this script directory.
set "SUBDIRS=Win32"
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "SUBDIRS=Win64 Win32"
for %%p in ("%SCRIPT_PATH%" "%SCRIPT_DRIVE%" "C:") do (
  for %%s in (%SUBDIRS%) do (
    if .%DEBUG%.==.1. echo Checking "%%~p\ezWinPorts\%%~s\bin\%~1.exe"
    if exist "%%~p\ezWinPorts\%%~s\bin\%~1.exe" (
      set "%~1=%%~p\ezWinPorts\%%~s\bin\%~1.exe"
      set "NUL=NUL"
      set "FILTER=| remplace / \\"
      goto :eof
    )
  )
)
goto :eof

:# Search for the unxutils.sourceforge.net port of a Unix program.
:UnxUtils %1=program. Returns variable %1 set to the exe full pathname.
:# Search in the standard location, or underneath this script directory.
for %%p in ("%SCRIPT_PATH%" "%SCRIPT_DRIVE%" "C:") do (
  if .%DEBUG%.==.1. echo Checking "%%~p\UnxUtils\usr\local\wbin\%~1.exe"
  if exist "%%~p\UnxUtils\usr\local\wbin\%~1.exe" (
    set "%~1=%%~p\UnxUtils\usr\local\wbin\%~1.exe"
    set "NUL=NUL"
    set "FILTER=| remplace -q \n \r\n | remplace -q \r\r \r"
    goto :eof
  )
)
goto :eof

:# Search for the gnuwin32.sourceforge.net port of a Unix program.
:GnuWin32 %1=program. Returns variable %1 set to the exe full pathname.
:# Search in the standard location, or underneath this script directory.
for %%p in ("%SCRIPT_PATH%" "%SCRIPT_DRIVE%" "C:") do (
  if .%DEBUG%.==.1. echo Checking "%%~p\GnuWin32\bin\%~1.exe"
  if exist "%%~p\GnuWin32\bin\%~1.exe" (
    set "%~1=%%~p\GnuWin32\bin\%~1.exe"
    set "NUL=NUL"
    set "FILTER="
    goto :eof
  )
)
goto :eof

:# Search for the Microsoft SUA port of a Unix program.
:SUA %1=program. Returns variable %1 set to the exe full pathname.
:# Search in its standard Windows subdirectory, or on the same drive as this script.
for %%p in ("%windir%" "%SCRIPT_DRIVE%\Windows") do (
  if .%DEBUG%.==.1. echo Checking "%%~p\SUA\common\%~1.exe"
  if exist "%%~p\SUA\common\%~1.exe" (
    set "%~1=%%~p\SUA\common\%~1.exe"
    set "NUL=/dev/null"
    set "FILTER=| remplace -q \n \r\n | remplace -q \r\r \r"
    goto :eof
  )
)
goto :eof

:# Search for the mingw.sourceforge.net port of a Unix program.
:MinGW %1=program. Returns variable %1 set to the exe full pathname.
:# Search in the standard location, or on the same drive as this script.
for %%d in ("%SCRIPT_DRIVE%" "C:") do (
  for %%p in ("\MinGW\msys\1.0\bin" "\MinGW\bin") do (
    if .%DEBUG%.==.1. echo Checking "%%d%%p\%~1.exe"
    if exist "%%d%%p\%~1.exe" (
      set "%~1=%%d%%p\%~1.exe"
      set "NUL=NUL"
      set "FILTER="
      goto :eof
    )
  )
)
goto :eof

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        Main                                                      #
:#                                                                            #
:#  Description     Process command line arguments                            #
:#                                                                            #
:#  Arguments       %*	    Command line arguments                            #
:#                                                                            #
:#  Notes 	                                                              #
:#                                                                            #
:#  History                                                                   #
:#                                                                            #
:#----------------------------------------------------------------------------#

:help
echo.
echo %SCRIPT% - Find files containing a given text string
echo.
echo Usage: trouve [switches] [directory] string
echo.
echo Switches:
echo   -?          This help
echo   --          End of switches. Allows searching for -i , etc.
echo   -D {dir}    Startup directory. Default: Current directory
echo   -e          Use the ezwinports.sourceforge.net port (default)
echo   -g          Use the gnuwin32.sourceforge.net port (3rd choice)
echo   -i          Ignore case in the search string
echo   -j          Ignore case in the file name (default)
echo   -J          Do not ignore case in the file name
echo   -l          List files that match. (Default: List all matches)
echo   -L          List files that do NOT match
echo   -m          Use the mingw.sourceforge.net port (5th choice)
echo   -n {name*}  Name template. Default: *.*
echo   -r          Recursive search in all subdirectories
echo   -s          Use the Microsoft SUA port (4th choice)
echo   -u          Use the unxutils.sourceforge.net port (2nd choice)
echo   -v          Verbose mode: Display the command and run it
echo   -V          Display the script version and exit
echo   -X          Display the command to run, but don't run it
goto :eof

:main
if .%DEBUG%.==.1. echo %ARG0% %*

set "VERBOSE=0"
set "NOEXEC=0"
set "FROM=."
set "GREPOPTS="			&:# grep options
set "-NAME=-iname"
set "NAME="
set "-MAXDEPTH=-maxdepth 1"
set "FILTER="
set "PORTS="
goto get_arg

:next2_arg
shift
:next_arg
shift
:get_arg
if .%1.==.. goto help
if "%~1"=="-?" goto help
if "%~1"=="/?" goto help
if "%~1"=="--" shift & goto start
if "%~1"=="-d" set "DEBUG=1" & goto next_arg
if "%~1"=="-D" set FROM=%2& goto next2_arg &:# Leave the %2 quoting unchanged
if "%~1"=="-e" set "PORTS=%PORTS% ezWinPorts" & goto next_arg
if "%~1"=="-g" set "PORTS=%PORTS% GnuWin32" & goto next_arg
if "%~1"=="-i" set "GREPOPTS=%GREPOPTS% -i" & goto next_arg
if "%~1"=="-j" set "-NAME=-iname" & goto next_arg
if "%~1"=="-J" set "-NAME=-name" & goto next_arg
if "%~1"=="-l" set "GREPOPTS=%GREPOPTS% -l" & goto next_arg
if "%~1"=="-L" set "GREPOPTS=%GREPOPTS% -L" & goto next_arg
if "%~1"=="-m" set "PORTS=%PORTS% MinGW" & goto next_arg
if "%~1"=="-n" set NAME=%2& goto next2_arg &:# Leave the %2 quoting unchanged
if "%~1"=="-r" set "-MAXDEPTH=" & goto next_arg
if "%~1"=="-s" set "PORTS=%PORTS% SUA" & goto next_arg
if "%~1"=="-u" set "PORTS=%PORTS% UnxUtils" & goto next_arg
if "%~1"=="-v" set "VERBOSE=1" & goto next_arg
if "%~1"=="-V" (echo.%VERSION%) & goto :eof
if "%~1"=="-X" set "NOEXEC=1" & goto next_arg

goto start

:start
:# Search all known ports if no specific one specified 
if "%PORTS%"=="" set "PORTS=ezWinPorts UnxUtils GnuWin32 SUA MinGW"

:# Search in the list of ports
for %%c in (find grep) do (
  set "%%c="
  for %%u in (%PORTS%) do if "!%%c!"=="" call :%%u %%c
  if "!%%c!"=="" ( :# Admit failure
    >&2 echo Error: Cannot find a Windows port of the Unix %%c program
    goto :eof
  )
  if .%DEBUG%.==.1. echo set "%%c=!%%c!"
  call :condquote %%c
)

if not '%2'=='' (
  set FROM=%1
  shift
)
if .%NAME%.==.. set "-NAME="
set "FINDOPTS=-type f"
if defined -MAXDEPTH set "FINDOPTS=%-MAXDEPTH% %FINDOPTS%"
if defined -NAME set "FINDOPTS=%FINDOPTS% %-NAME%"
if defined NAME set "FINDOPTS=%FINDOPTS% %NAME%"
:# Note: The "" around %1 are necessary to support strings with spaces.
:# Note: The "" around {} are necessary to support pathnames with spaces.
:# 2013-04-03 JFL Removed one pair of "quotes" around {}, as the third pair caused the ezWinPorts grep to fail.
set CMDLINE=%find% %FROM% %FINDOPTS% -exec %grep%%GREPOPTS% -- %1 "{}" %NUL% ";"
if %VERBOSE%==1 echo %CMDLINE%
if %VERBOSE%==0 if %NOEXEC%==1 echo %CMDLINE%
if %NOEXEC%==0 %CMDLINE% %FILTER%

