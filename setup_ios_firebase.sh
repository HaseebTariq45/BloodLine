#!/bin/bash

# iOS Firebase Setup Script

echo "========== BloodLine iOS Firebase Setup ==========="
echo "Preparing your iOS project for Firebase..."
echo "Note: This project requires iOS 14.0 or higher due to Google Maps plugin requirements"

# Change to the ios directory
cd ios

# Check if the GoogleService-Info.plist exists
if [ -f Runner/GoogleService-Info.plist ]; then
  echo "✅ GoogleService-Info.plist found"
else
  echo "❌ Error: GoogleService-Info.plist not found in ios/Runner/"
  echo "Please download it from Firebase Console and place it in the ios/Runner directory"
  exit 1
fi

# Update Podfile if it exists
if [ -f Podfile ]; then
  echo "✅ Podfile found"
else
  echo "❌ Podfile not found, please ensure it was created correctly"
  exit 1
fi

# Install pods
echo "Installing CocoaPods dependencies..."
pod install

# Check if pod install was successful
if [ $? -eq 0 ]; then
  echo "✅ Pods installed successfully"
else
  echo "❌ Error: Pod installation failed"
  exit 1
fi

# Return to the root directory
cd ..

echo ""
echo "========== iOS Firebase Setup Complete ==========="
echo ""
echo "Next steps:"
echo "1. Open the workspace in Xcode: ios/Runner.xcworkspace"
echo "2. Ensure bundle identifier matches the one in Firebase Console (com.haseeb.bloodline)"
echo "3. Verify that deployment target is set to iOS 14.0 or higher"
echo "4. Build and run on a real device or simulator"
echo ""
echo "For CI/CD systems:"
echo "- Use the generated Podfile and workspace for building the app"
echo "- Ensure your CI/CD runner has CocoaPods installed"
echo "- Make sure deployment target is set to iOS 14.0 for all configurations"
echo ""
echo "Happy coding! 🚀" 