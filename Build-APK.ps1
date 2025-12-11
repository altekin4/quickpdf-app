param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("debug", "release")]
    [string]$BuildType = "debug",
    
    [Parameter(Mandatory=$false)]
    [switch]$Install,
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean
)

# Renkli çıktı fonksiyonları
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Warning { param($Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }
function Write-Info { param($Message) Write-Host "ℹ $Message" -ForegroundColor Blue }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       QuickPDF APK Builder v1.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Info "Build Type: $BuildType"
Write-Host ""

# Proje klasörüne git
$ProjectPath = Join-Path $PSScriptRoot "quickpdf_app"
if (-not (Test-Path $ProjectPath)) {
    Write-Error "quickpdf_app klasörü bulunamadı!"
    exit 1
}

Set-Location $ProjectPath

# Flutter kontrolü
Write-Warning "1. Flutter kurulumu kontrol ediliyor..."
try {
    $null = flutter --version 2>$null
    Write-Success "Flutter kurulu"
} catch {
    Write-Error "Flutter kurulu değil!"
    exit 1
}

# Android cihaz kontrolü
Write-Warning "2. Android cihaz kontrol ediliyor..."
$devices = flutter devices 2>$null
if ($devices -match "android") {
    Write-Success "Android cihaz bulundu"
    $hasAndroidDevice = $true
} else {
    Write-Warning "Android cihaz bulunamadı (sadece APK oluşturulacak)"
    $hasAndroidDevice = $false
}

# Cache temizleme
if ($Clean) {
    Write-Warning "3. Cache temizleniyor..."
    flutter clean | Out-Null
    Write-Success "Cache temizlendi"
}

# Dependencies
Write-Warning "4. Dependencies alınıyor..."
try {
    flutter pub get
    Write-Success "Dependencies alındı"
} catch {
    Write-Error "Dependencies alınamadı!"
    exit 1
}

# APK Build
Write-Warning "5. APK build ediliyor ($BuildType)..."
try {
    if ($BuildType -eq "release") {
        flutter build apk --release --split-per-abi
    } else {
        flutter build apk --debug --split-per-abi
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "       APK BUILD BAŞARILI!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    # APK dosyalarını listele
    Write-Info "Oluşturulan APK dosyaları:"
    $apkPath = "build\app\outputs\flutter-apk"
    $apkFiles = Get-ChildItem -Path $apkPath -Filter "*$BuildType.apk" -ErrorAction SilentlyContinue
    
    foreach ($file in $apkFiles) {
        Write-Host "  • $($file.Name)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Info "APK Konumu: $(Resolve-Path $apkPath)"
    
    # Cihaza kurulum
    if ($Install -and $hasAndroidDevice) {
        Write-Warning "Cihaza kuruluyor..."
        try {
            flutter install
            Write-Success "Uygulama cihaza kuruldu!"
        } catch {
            Write-Error "Cihaza kurulum başarısız!"
        }
    }
    
} catch {
    Write-Error "APK build edilemedi!"
    Write-Host ""
    Write-Warning "Alternatif çözümler:"
    Write-Host "1. GitHub Actions kullanın"
    Write-Host "2. Web versiyonu test edin: flutter run -d chrome"
    Write-Host "3. Proje yolunu kısaltın"
    exit 1
}

Write-Host ""
Write-Success "İşlem tamamlandı!"