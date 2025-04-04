#!/bin/bash

# Script to fix common permission issues in CI/CD environment

echo "========== Fixing CI/CD permissions ==========="

# Check for Xcode version
echo "Xcode version:"
xcodebuild -version

# Check for Flutter version
echo "Flutter version:"
flutter --version

# Fix potential permission issues
echo "Fixing permission issues..."

# Make sure Pods directory exists
if [ -d "ios/Pods" ]; then
  echo "Fixing Pods directory permissions..."
  chmod -R 755 ios/Pods
fi

# Make sure GoogleService-Info.plist exists and has correct permissions
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
  echo "Fixing GoogleService-Info.plist permissions..."
  chmod 644 ios/Runner/GoogleService-Info.plist
else
  echo "Warning: GoogleService-Info.plist not found!"
fi

# Set correct permissions for project files
echo "Setting permissions for project files..."
chmod -R 755 ios

# Check and fix permissions for Flutter build directory
if [ -d "build" ]; then
  echo "Fixing build directory permissions..."
  chmod -R 755 build
fi

# Fix permissions for Info.plist
if [ -f "ios/Runner/Info.plist" ]; then
  echo "Fixing Info.plist permissions..."
  chmod 644 ios/Runner/Info.plist
fi

# Fix permissions for AppDelegate.swift
if [ -f "ios/Runner/AppDelegate.swift" ]; then
  echo "Fixing AppDelegate.swift permissions..."
  chmod 644 ios/Runner/AppDelegate.swift
fi

# Fix permissions for project.pbxproj
if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
  echo "Fixing project.pbxproj permissions..."
  chmod 644 ios/Runner.xcodeproj/project.pbxproj
fi

# Make sure the xcconfig directory is accessible
if [ -d "ios/Flutter" ]; then
  echo "Fixing Flutter configs permissions..."
  chmod -R 755 ios/Flutter
fi

# Check if Podfile.lock exists
if [ -f "ios/Podfile.lock" ]; then
  echo "Podfile.lock exists. Removing it for clean install..."
  rm ios/Podfile.lock
fi

# Clean any leftover derived data which can cause issues
if [ -d "~/Library/Developer/Xcode/DerivedData" ]; then
  echo "Cleaning derived data..."
  rm -rf ~/Library/Developer/Xcode/DerivedData/*
fi

echo "Permissions fixed!"
echo ""

# Print bundle identifier used by the project
echo "Bundle identifier (from project.pbxproj):"
grep -A1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -2

# Print bundle identifier used by Firebase
echo "Bundle identifier (from GoogleService-Info.plist):"
grep -A1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist | head -2

echo ""
echo "========== CI/CD permissions fixed ===========" 