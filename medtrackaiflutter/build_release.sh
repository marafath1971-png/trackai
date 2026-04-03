#!/bin/bash

# MedTrack AI — Production Build Script
# This script prepares and builds the Android App Bundle (.aab) for Google Play.

set -e

echo "🚀 Starting Production Build Process..."

# 1. Environment Check
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file missing. Please create it with GEMINI_API_KEY."
    exit 1
fi

# 2. Keystore Check
if [ ! -f "android/key.properties" ]; then
    echo "⚠️  Warning: android/key.properties not found."
    echo "Creating from example..."
    cp android/key.properties.example android/key.properties
    echo "Please update android/key.properties with your real keystore values."
fi

# 3. Clean and Fetch
echo "🧹 Cleaning project..."
flutter clean
echo "📦 Fetching dependencies..."
flutter pub get

# 4. Static Analysis
echo "🔍 Running static analysis..."
if ! flutter analyze; then
    echo "❌ Analysis failed. Please fix errors before building for production."
    exit 1
fi

# 5. Build AAB
echo "🏗️  Building Android App Bundle..."
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

echo "---------------------------------------------------"
echo "✅ SUCCESS! Your production build is ready at:"
echo "build/app/outputs/bundle/release/app-release.aab"
echo "---------------------------------------------------"
echo "Note: If the build failed with 'Keystore' errors, ensure your key.jks exists"
echo "and your android/key.properties points to the correct absolute path."
