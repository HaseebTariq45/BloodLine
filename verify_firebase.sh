#!/bin/bash

# Script to verify Firebase configuration

echo "========== Verifying Firebase Configuration ==========="

# Check for GoogleService-Info.plist
if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
  echo "❌ ERROR: GoogleService-Info.plist is missing!"
  exit 1
else
  echo "✅ GoogleService-Info.plist found"
fi

# Verify that the bundle ID in GoogleService-Info.plist matches our app
FIREBASE_BUNDLE_ID=$(grep -A1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist | grep string | sed 's/.*<string>\(.*\)<\/string>.*/\1/' || echo "NOT_FOUND")
XCODE_BUNDLE_ID=$(grep "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -1 | awk '{print $3}' | sed 's/;//g' || echo "NOT_FOUND")

echo "Firebase Bundle ID: $FIREBASE_BUNDLE_ID"
echo "Xcode Bundle ID: $XCODE_BUNDLE_ID"

if [ "$FIREBASE_BUNDLE_ID" != "$XCODE_BUNDLE_ID" ]; then
  echo "❌ WARNING: Bundle ID mismatch between Firebase ($FIREBASE_BUNDLE_ID) and Xcode ($XCODE_BUNDLE_ID)"
  echo "This should be fixed for proper Firebase integration."
else
  echo "✅ Bundle IDs match"
fi

# Check for API key in GoogleService-Info.plist
if grep -q "API_KEY" ios/Runner/GoogleService-Info.plist; then
  echo "✅ API_KEY found in GoogleService-Info.plist"
else
  echo "❌ ERROR: API_KEY not found in GoogleService-Info.plist"
  echo "This is required for Firebase authentication services."
  exit 1
fi

# Check AppDelegate.swift for Firebase initialization
if grep -q "FirebaseApp.configure()" ios/Runner/AppDelegate.swift; then
  echo "✅ FirebaseApp.configure() found in AppDelegate.swift"
else
  echo "❌ ERROR: FirebaseApp.configure() not found in AppDelegate.swift"
  echo "Add 'import Firebase' and 'FirebaseApp.configure()' to initialize Firebase."
  exit 1
fi

# Check if Firebase frameworks are included in the Podfile
if grep -q "pod 'Firebase" ios/Podfile || grep -q "firebase_core" ios/Podfile; then
  echo "✅ Firebase dependencies found in Podfile"
else
  echo "❌ WARNING: No Firebase dependencies found in Podfile"
  echo "Make sure firebase_core is included in your pubspec.yaml"
fi

# Output verification result
echo ""
echo "Firebase configuration verification complete. ✅"
echo "Note: This script only checks basic configuration. Further errors may still occur at runtime."
echo "========== Firebase Verification Complete ===========" 