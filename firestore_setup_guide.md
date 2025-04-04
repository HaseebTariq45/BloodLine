# Firestore Setup Guide for App Updates

This guide explains how to set up Firestore to manage app updates for your BloodLine app.

## Step 1: Set Up Firestore Document Structure

1. Open the [Firebase Console](https://console.firebase.google.com/) and select your project
2. Go to **Firestore Database** in the left sidebar
3. If you haven't already, create a Firestore database (start in test mode for development)
4. Create a new collection called `app_updates`
5. Within this collection, create a document with ID `latest_version`
6. Add the following fields to this document:

   | Field Name    | Type   | Description                            |
   |---------------|--------|----------------------------------------|
   | latestVersion | String | Version number (e.g., "1.1.0")         |
   | releaseNotes  | String | Update description with new features   |
   | downloadUrl   | String | (Optional) Direct download URL for APK |
   | apkFileId     | String | Google Drive file ID of the APK        |

   Example values:
   - **latestVersion**: "1.1.0"
   - **releaseNotes**: "What's new in version 1.1.0:\n\n• New update feature added\n• Splash screen redesigned\n• Bug fixes and performance improvements"
   - **downloadUrl**: "" (leave empty if using apkFileId)
   - **apkFileId**: "YOUR_GOOGLE_DRIVE_APK_FILE_ID"

## Step 2: Upload Your APK to Google Drive

1. Build your APK file:
   ```
   flutter build apk --release
   ```
2. Upload the APK to Google Drive
3. Right-click on the APK file and select "Get link"
4. Click "Anyone with the link" to make it publicly accessible
5. Copy the link and extract the File ID (the part after `/d/` and before `/view`)
6. Update the `apkFileId` field in your Firestore document with this ID

## Step 3: Security Rules (Important)

Make sure your Firestore security rules allow reading the update information:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /app_updates/{document} {
      // Allow anyone to read update information
      allow read: true;
      // Only allow authorized users to write
      allow write: if false; // Or replace with your admin authentication logic
    }
    
    // Your other rules...
  }
}
```

## Step 4: Releasing Updates

When you want to release a new update:

1. Build a new APK with an updated version number in `pubspec.yaml`
2. Upload the new APK to Google Drive
3. Get the new file ID
4. Update your Firestore document:
   - Increment the `latestVersion` field
   - Update the `releaseNotes` field
   - Update the `apkFileId` field with the new file ID

## Advantages of This Approach

1. **Dynamic Updates**: You can change the update info without releasing a new app version
2. **Flexible Control**: Enable or disable updates by changing Firestore data
3. **Versioned Updates**: Manage different versions for different user segments
4. **Easy Maintenance**: Update information in one central place

## Troubleshooting

- **Permission Issues**: Make sure your Firestore security rules allow reading the update document
- **Download Errors**: Ensure the APK file is publicly accessible on Google Drive
- **Updates Not Showing**: Check that the version in Firestore is higher than the app's current version 