# Blood Donation App - Firebase Cloud Functions

This directory contains the Cloud Functions that power the push notification system for the Blood Donation app.

## Key Function:

- `sendNotificationOnCreate`: Automatically sends push notifications when someone responds to a blood request

## How It Works

1. When someone responds to a blood request, the app creates a notification document in the Firestore `notifications` collection
2. This Cloud Function triggers on the creation of that document
3. It retrieves the requester's device tokens from their user document
4. It sends a push notification to those devices via Firebase Cloud Messaging
5. The notification includes the responder's name as requested

## Deployment Instructions

### Prerequisites

1. Install the Firebase CLI if you haven't already:
```
npm install -g firebase-tools
```

2. Login to Firebase:
```
firebase login
```

3. Initialize your project (if not already done):
```
firebase init
```

### Deploying the Functions

Deploy your functions to Firebase:

```
cd functions
npm install
firebase deploy --only functions
```

## Testing

After deployment, you can test the push notification system by:

1. Having one user create a blood request
2. Having another user respond to that request
3. The requester should receive a push notification with the responder's name

## Troubleshooting

If notifications are not being received:

1. Check Firebase Functions logs for any errors
2. Verify that device tokens are being correctly saved in Firestore
3. Ensure that the app has notification permissions on the device
