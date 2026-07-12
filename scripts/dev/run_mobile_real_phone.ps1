param(
    [string]$BackendUrl = "http://127.0.0.1:8080"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$mobileDir = Join-Path $repoRoot "apps\mobile"

Write-Host "SmartKash mobile dev run" -ForegroundColor Cyan
Write-Host "Backend URL: $BackendUrl"

try {
    $health = Invoke-WebRequest -UseBasicParsing "http://localhost:8080/actuator/health" -TimeoutSec 5
    Write-Host "Backend health check: $($health.Content)" -ForegroundColor Green
} catch {
    Write-Host "Backend is not reachable at http://localhost:8080/actuator/health" -ForegroundColor Yellow
    Write-Host "Start backend first: cd services/backend; .\mvnw.cmd spring-boot:run" -ForegroundColor Yellow
}

Write-Host "Checking connected Android devices..."
adb devices

Write-Host "Mapping Android device/emulator port 8080 to PC localhost:8080..."
adb reverse tcp:8080 tcp:8080

Write-Host "Running Flutter app with stable adb-reverse backend URL..."
Push-Location $mobileDir
try {
    flutter run --dart-define "SMARTKASH_API_BASE_URL=$BackendUrl"
} finally {
    Pop-Location
}
