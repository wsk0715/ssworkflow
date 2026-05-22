$EXTRACT_PATH = "build/extracted"
$APP_NAME = "nl2sql-app"

Write-Host "--- [1/4] Building JAR locally.. ---" -ForegroundColor Cyan
./gradlew bootJar -x test --parallel

if ($LASTEXITCODE -ne 0) {
    Write-Host "--- Build Failed! Terminating.. ---" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "--- [2/4] Extracting Layers Locally.. ---" -ForegroundColor Cyan
if (Test-Path $EXTRACT_PATH) {
    Remove-Item -Recurse -Force $EXTRACT_PATH
}
New-Item -ItemType Directory -Path $EXTRACT_PATH | Out-Null
java -Djarmode=tools -jar "build/libs/app.jar" extract --layers --launcher --destination $EXTRACT_PATH

Write-Host "--- [3/4] Docker Compose Build & Up.. ---" -ForegroundColor Cyan
docker-compose up -d app --build

Write-Host "--- [4/4] Application is Starting.. ---" -ForegroundColor Green
docker logs -f "$APP_NAME"
