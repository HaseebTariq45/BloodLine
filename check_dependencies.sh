#!/bin/bash

# Script to check for dependency conflicts and version mismatches

echo "========== Checking Dependencies ==========="

# Check Flutter version
echo "Flutter version:"
flutter --version

# Check iOS software versions
echo "Xcode version:"
xcodebuild -version

echo "CocoaPods version:"
pod --version

# Check for Flutter pub outdated
echo "Running flutter pub outdated to check for dependency updates..."
flutter pub outdated

# Check pubspec.yaml for Firebase Core
echo "Checking pubspec.yaml for critical dependencies..."
if grep -q "firebase_core:" pubspec.yaml; then
  echo "✅ firebase_core found in pubspec.yaml"
else
  echo "❌ ERROR: firebase_core not found in pubspec.yaml"
  echo "This is required for any Firebase functionality"
fi

# Check for explicit Firebase versions
if grep -q "firebase_" pubspec.yaml; then
  echo "Firebase packages found. Checking versions..."
  grep "firebase_" pubspec.yaml
  
  # Check if firebase_core is listed first
  FIRST_FIREBASE=$(grep -n "firebase_" pubspec.yaml | sort -n | head -1)
  if echo "$FIRST_FIREBASE" | grep -q "firebase_core"; then
    echo "✅ firebase_core is listed first among Firebase packages"
  else
    echo "⚠️ WARNING: firebase_core should ideally be listed first among Firebase packages"
  fi
fi

# Check specifically for Google Maps dependencies
echo "Checking for Google Maps dependencies..."
if grep -q "google_maps_flutter:" pubspec.yaml; then
  echo "✅ google_maps_flutter found in pubspec.yaml"
  
  # Check for correct version that supports iOS 14+
  MAPS_VERSION=$(grep "google_maps_flutter:" pubspec.yaml | sed 's/.*:\s*\^\(.*\)/\1/')
  if [[ -n "$MAPS_VERSION" ]]; then
    echo "Google Maps Flutter version: $MAPS_VERSION"
    if [[ "$MAPS_VERSION" < "2.2.0" ]]; then
      echo "❌ WARNING: google_maps_flutter version may be too old for iOS 14+"
      echo "Consider updating to at least version 2.2.0"
    fi
  fi
  
  # Check for google_maps_flutter_ios plugin
  if grep -q "google_maps_flutter_ios:" pubspec.yaml; then
    echo "✅ google_maps_flutter_ios found in pubspec.yaml"
    # Show the version
    grep "google_maps_flutter_ios:" pubspec.yaml
    echo "This plugin requires GoogleMaps 8.4.0 or higher"
  fi
  
  # Check for proper iOS version in Podfile
  if grep -q "platform :ios, '14.0'" ios/Podfile; then
    echo "✅ iOS deployment target set to 14.0 in Podfile (required for Google Maps)"
  else
    echo "❌ ERROR: iOS deployment target in Podfile might not be set to 14.0"
    echo "Google Maps Flutter plugin requires iOS 14.0+"
  fi
  
  # Check for GoogleMaps in Podfile
  if grep -q "pod 'GoogleMaps'" ios/Podfile; then
    PODFILE_MAPS_VERSION=$(grep "pod 'GoogleMaps'" ios/Podfile | sed -n "s/.*'~> \(.*\)'.*/\1/p")
    echo "GoogleMaps pod version in Podfile: $PODFILE_MAPS_VERSION"
    if [[ -n "$PODFILE_MAPS_VERSION" && "$PODFILE_MAPS_VERSION" < "8.4.0" ]]; then
      echo "❌ ERROR: GoogleMaps pod version in Podfile is too old"
      echo "google_maps_flutter_ios requires GoogleMaps 8.4.0 or higher"
    else
      echo "✅ GoogleMaps pod version is compatible with google_maps_flutter_ios"
    fi
  else
    echo "❓ GoogleMaps pod not explicitly defined in Podfile"
  fi
else
  echo "❓ google_maps_flutter not found in pubspec.yaml, but imported in code?"
fi

# Check for Firebase dependencies
echo "Checking for Firebase dependencies..."
if grep -q "firebase_core" pubspec.yaml; then
  echo "✅ firebase_core found in pubspec.yaml"
else
  echo "❌ WARNING: firebase_core not found in pubspec.yaml"
  echo "This is required for Firebase functionality"
fi

# Check for potential conflicts related to Firebase
echo "Checking for potential dependency conflicts..."
if grep -q "firebase_messaging" pubspec.yaml && grep -q "local_notifications" pubspec.yaml; then
  echo "⚠️ Both firebase_messaging and local_notifications found"
  echo "Ensure you're using compatible versions"
fi

# Check for common dependency version conflicts
echo "Checking for common dependency conflicts..."

# Check if using intl package (common source of conflicts)
if grep -q "intl:" pubspec.yaml; then
  echo "intl package found, checking version..."
  INTL_VERSION=$(grep "intl:" pubspec.yaml | sed 's/.*:\s*\^\(.*\)/\1/')
  if [[ -n "$INTL_VERSION" && "$INTL_VERSION" < "0.17.0" ]]; then
    echo "⚠️ WARNING: intl version $INTL_VERSION may conflict with newer Firebase packages"
    echo "Consider updating to at least version 0.17.0"
  fi
fi

echo "========== Dependency Check Complete ===========" 