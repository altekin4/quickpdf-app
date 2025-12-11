@echo off
echo Docker ile APK Build
echo.

set BUILD_TYPE=%1
if "%BUILD_TYPE%"=="" set BUILD_TYPE=debug

echo Build Type: %BUILD_TYPE%
echo.

REM Docker image build et
echo Docker image oluşturuluyor...
docker build -f Dockerfile.build -t quickpdf-builder .

REM APK build et
echo APK build ediliyor...
docker run --rm -v "%cd%\quickpdf_app:/app/source" -v "%cd%\output:/app/output" quickpdf-builder %BUILD_TYPE%

echo.
echo APK dosyaları output klasöründe!
if exist "output" explorer output

pause