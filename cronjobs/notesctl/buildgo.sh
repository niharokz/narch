#!/bin/bash
 
#
#       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
#       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
#       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
#       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
#       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
#       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#       DRAFTED BY [https://nih.ar] ON 03-04-2026
#       SOURCE [build.sh] LAST MODIFIED ON 03-04-2026
#

set -e

# 🔥 Load Go env from zprofile
source ~/.zprofile 2>/dev/null

cd "$(dirname "$0")"

echo "🔍 Detecting Go entry file..."

# find main package file (prefer main.go, else any with package main)
MAIN_FILE=""

if [[ -f "main.go" ]]; then
  MAIN_FILE="main.go"
else
  MAIN_FILE=$(grep -l "package main" *.go 2>/dev/null | head -n 1)
fi

if [[ -z "$MAIN_FILE" ]]; then
  echo "❌ No main Go file found"
  exit 1
fi

# derive binary name from file (remove .go)
BINARY_NAME=$(basename "$MAIN_FILE" .go)

echo "📦 Using entry file: $MAIN_FILE"
echo "🔨 Building binary: $BINARY_NAME"

# optional: tidy modules if go.mod exists
if [[ -f "go.mod" ]]; then
  echo "📦 Running go mod tidy..."
  go mod tidy
fi

go build -o "$BINARY_NAME"

echo "✅ Build complete: $(pwd)/$BINARY_NAME"
