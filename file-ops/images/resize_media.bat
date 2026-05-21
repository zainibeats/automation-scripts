@echo off
:: resize_media.bat
:: Purpose: Batch resize image files using ImageMagick
:: Requirements: ImageMagick must be installed and in system PATH
::
:: Features:
::   - Processes multiple image formats (GIF, PNG, JPG, JPEG)
::   - Recursive directory processing
::   - User-specified resize percentage
::   - Single or all file type processing
::
:: Usage:
::   1. Enter target directory (or . for current)
::   2. Specify resize percentage (e.g., 130 = +30%, 50 = half size)
::   3. Choose file type (gif/png/jpg) or 'all' for every supported format

set /p DIR="Enter folder path (or press Enter for current folder): "
if "%DIR%"=="" set "DIR=."

:get_size
set /p SIZE="Enter resize percentage (e.g., 130 for 30%% larger, 50 for half size): "
if "%SIZE%"=="" (
    echo Please enter a size value.
    goto get_size
)

set /p TYPE="Enter file type (gif/png/jpg/all): "
if "%TYPE%"=="" set "TYPE=all"

if /i "%TYPE%"=="all" (
    set "PATTERN=*.gif *.png *.jpg *.jpeg"
) else (
    set "PATTERN=*.%TYPE%"
)

echo.
echo Processing files in: %DIR%
echo Resize to: %SIZE%%%
echo File types: %PATTERN%
echo.

for /R "%DIR%" %%F in (%PATTERN%) do (
    echo Processing: %%F
    magick mogrify -resize %SIZE%%% "%%F"
)

echo.
echo All files have been resized.
pause
