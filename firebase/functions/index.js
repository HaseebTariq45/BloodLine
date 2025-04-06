const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Firebase Cloud Function to send push notifications to devices
 * This function can be called from the app using Firebase Functions SDK
 */
exports.sendPushNotification = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { tokens, notification, data: messageData } = data;

  if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with a valid array of device tokens.'
    );
  }

  if (!notification || !notification.title || !notification.body) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with a valid notification object containing title and body.'
    );
  }

  try {
    // Create the message
    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: messageData || {},
      tokens: tokens, // Multiple tokens (up to 500)
    };

    // Send the message
    const response = await admin.messaging().sendMulticast(message);
    
    console.log(`Successfully sent message: ${response.successCount} successful, ${response.failureCount} failed`);
    
    // Return the response
    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      results: response.responses.map(res => ({
        success: res.success,
        messageId: res.messageId,
        error: res.error ? res.error.toJSON() : null,
      })),
    };
  } catch (error) {
    console.error('Error sending message:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Firebase Cloud Function to send a notification when a new notification document is created
 * This is triggered automatically when a notification is added to Firestore
 */
exports.sendNotificationOnCreate = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    const userId = notificationData.userId;
    
    if (!userId) {
      console.error('No userId found in notification data');
      return null;
    }
    
    try {
      // Get the user document to find device tokens
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        console.error(`User document not found for userId: ${userId}`);
        return null;
      }
      
      const userData = userDoc.data();
      const deviceTokens = userData.deviceTokens || [];
      
      if (deviceTokens.length === 0) {
        console.log(`No device tokens found for user: ${userId}`);
        return null;
      }
      
      // Create the message
      const message = {
        notification: {
          title: notificationData.title,
          body: notificationData.body,
        },
        data: {
          notificationId: context.params.notificationId,
          type: notificationData.type || 'general',
          // Add any metadata
          ...(notificationData.metadata || {}),
        },
        tokens: deviceTokens,
      };
      
      // Send the message
      const response = await admin.messaging().sendMulticast(message);
      
      console.log(`Successfully sent notification: ${response.successCount} successful, ${response.failureCount} failed`);
      
      // Update tokens if there are any invalid ones
      if (response.failureCount > 0) {
        const invalidTokens = [];
        
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const error = resp.error;
            if (error.code === 'messaging/invalid-registration-token' ||
                error.code === 'messaging/registration-token-not-registered') {
              invalidTokens.push(deviceTokens[idx]);
            }
          }
        });
        
        if (invalidTokens.length > 0) {
          // Remove invalid tokens
          const validTokens = deviceTokens.filter(token => !invalidTokens.includes(token));
          
          // Update the user document
          await admin.firestore().collection('users').doc(userId).update({
            deviceTokens: validTokens,
          });
          
          console.log(`Removed ${invalidTokens.length} invalid tokens for user: ${userId}`);
        }
      }
      
      return {
        success: true,
        notificationId: context.params.notificationId,
      };
    } catch (error) {
      console.error('Error sending notification:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }); 