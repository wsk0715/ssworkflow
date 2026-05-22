#!/bin/bash

EXTRACT_PATH="build/extracted"
APP_NAME="nl2sql-app"

# Color constants
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
PLAIN='\033[0m' # No Color

echo -e "${CYAN}--- [1/4] Building JAR locally.. ---${PLAIN}"
./gradlew bootJar -x test --parallel

if [ $? -ne 0 ]; then
    echo -e "${RED}--- Build Failed! Terminating.. ---${PLAIN}"
    exit 1
fi

echo -e "${CYAN}--- [2/4] Extracting Layers Locally.. ---${PLAIN}"
if [ -d "$EXTRACT_PATH" ]; then
    rm -rf "$EXTRACT_PATH"
fi
mkdir -p "$EXTRACT_PATH"

java -Djarmode=tools -jar "build/libs/app.jar" extract --layers --launcher --destination "$EXTRACT_PATH"

echo -e "${CYAN}--- [3/4] Docker Compose Build & Up.. ---${PLAIN}"
docker-compose up -d app --build

echo -e "${GREEN}--- [4/4] Application is Starting.. ---${PLAIN}"
docker logs -f "${APP_NAME}"
