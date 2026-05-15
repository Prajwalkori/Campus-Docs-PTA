#!/bin/bash
set -e

echo "Downloading Flutter..."
# Clone Flutter stable branch
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Add flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Check Flutter version
flutter --version

# Enable Web
flutter config --enable-web

# Get dependencies
flutter pub get

# Build the Flutter web app
echo "Building Flutter Web App..."
flutter build web --release
