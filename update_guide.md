# App Update System - Dropbox Setup Guide

This guide explains how to set up the in-app update system using Dropbox.

## Step 1: Create and Upload the JSON File

1. Create a file named `update_info.json` with the following structure:
   ```json
   {
     "latestVersion": "1.1.0",
     "downloadUrl": "https://www.dropbox.com/s/YOUR_PATH/bloodline_update.apk?dl=0",
     "releaseNotes": "What's new in version 1.1.0:\n\n• New update feature added\n• Splash screen redesigned\n• Bug fixes and performance improvements"
   }
   ```

2. Upload this file to Dropbox
3. Right-click on the file in Dropbox and select "Share"
4. Click "Create a link" to make it publicly accessible
5. Copy the link - it will look like: `https://www.dropbox.com/s/abcdefg/update_info.json?dl=0`

## Step 2: Configure the App Updater

1. In `lib/utils/app_updater.dart`, update the `updateInfoUrl` constant:
   ```dart
   static const String updateInfoUrl = 'https://www.dropbox.com/s/YOUR_PATH/update_info.json?dl=1';
   ```
   Replace `YOUR_PATH` with the path from your Dropbox shared link. Note that we changed `dl=0` to `dl=1` to make it a direct download link.

## Step 3: Upload Your APK File

1. Build your APK file with the new version number:
   ```
   flutter build apk --release
   ```
2. Upload the APK to Dropbox
3. Right-click on the APK file and select "Share"
4. Click "Create a link" to make it publicly accessible
5. Copy the link - it will look like: `https://www.dropbox.com/s/abcdefg/bloodline_update.apk?dl=0`
6. Update your `update_info.json` file with the new APK URL:
   ```json
   "downloadUrl": "https://www.dropbox.com/s/abcdefg/bloodline_update.apk?dl=0"
   ```
   Note: The code will automatically convert `dl=0` to `dl=1` to make it a direct download link.

## Step 4: Testing Updates

You can test the update system in two ways:

### Method 1: Using the JSON file (Production Approach)

1. Make sure your `updateInfoUrl` in `AppUpdater` points to the JSON file on Dropbox with `dl=1`
2. Use the `checkForUpdates()` method in `AppProvider` without modification

### Method 2: Direct APK URL (Testing Approach)

In `lib/providers/app_provider.dart`, uncomment and use the direct URL method:

```dart
// Method 2: Using a direct APK URL (easier for testing)
final updateInfo = await AppUpdater.useDirectApkUrl(
  "https://www.dropbox.com/s/abcdefg/bloodline_update.apk?dl=0",
  "1.1.0"
);
```

## Important Notes

1. **Version Numbers**: Always increment the version number in the JSON file when uploading a new APK.
2. **Dropbox Bandwidth Limits**: Dropbox has bandwidth limits for shared links. For production apps with many users, consider upgrading to Dropbox Business or using a more robust solution.
3. **Direct Download**: The app automatically converts Dropbox links to direct download links by changing `dl=0` to `dl=1`.

## Troubleshooting

- **Download Errors**: Ensure both files are publicly accessible on Dropbox
- **Installation Issues**: Check that all required Android permissions are properly set up
- **Update Not Showing**: Make sure the version in JSON is higher than the app's current version 