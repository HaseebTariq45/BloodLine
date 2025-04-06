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

/**
 * Cloud Function that triggers when a new document is created in the push_notifications collection.
 * It sends push notifications to the specified device tokens using Firebase Cloud Messaging.
 */
exports.sendPushNotificationOnCreate = functions.firestore
  .document('push_notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    try {
      const notificationId = context.params.notificationId;
      const notificationData = snapshot.data();
      
      console.log(`Processing push notification ${notificationId}`);
      
      const deviceTokens = notificationData.tokens || [];
      
      if (deviceTokens.length === 0) {
        console.log('No device tokens provided');
        return await updatePushNotificationStatus(snapshot.ref, 'error', 'No device tokens provided');
      }
      
      // Process result stats
      let totalSuccess = 0;
      let totalFailure = 0;
      let errorDetails = [];
      
      // Create notification payload
      const message = {
        notification: notificationData.notification,
        data: notificationData.data || {},
        android: {
          priority: 'high',
          notification: {
            icon: 'ic_stat_blooddrop',
            color: '#E53935',
            priority: 'max',
            default_vibrate_timings: true,
            default_sound: true,
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              content_available: 1,
            }
          }
        },
        tokens: deviceTokens,
      };
      
      try {
        // Send message
        const response = await admin.messaging().sendMulticast(message);
        
        // Add to totals
        totalSuccess += response.successCount;
        totalFailure += response.failureCount;
        
        // Log and collect any errors
        if (response.failureCount > 0) {
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              const token = deviceTokens[idx];
              const error = resp.error.toJSON();
              console.error(`Error sending to token ${token.substr(0, 10)}...: ${error.code}`, error);
              
              errorDetails.push({
                token: token.substr(0, 10) + '...',
                code: error.code,
                message: error.message
              });
              
              // If token is invalid, try to find and remove it from any user document
              if (error.code === 'messaging/invalid-registration-token' || 
                  error.code === 'messaging/registration-token-not-registered') {
                removeInvalidTokenFromAllUsers(token);
              }
            }
          });
        }
      } catch (error) {
        console.error('Error sending batch:', error);
        errorDetails.push({
          batch: `All tokens`,
          code: error.code || 'unknown',
          message: error.message
        });
        totalFailure += deviceTokens.length;
      }
      
      // Update push notification document with delivery status
      const status = totalSuccess > 0 ? 'delivered' : 'failed';
      await updatePushNotificationStatus(snapshot.ref, status, null, totalSuccess, totalFailure, errorDetails);
      
      // Log final results
      console.log(`Push notification ${notificationId} processed with status ${status}: ${totalSuccess} successful, ${totalFailure} failed`);
      
      return { success: (totalSuccess > 0), successCount: totalSuccess, failureCount: totalFailure };
    } catch (error) {
      console.error('Unhandled error processing push notification:', error);
      return await updatePushNotificationStatus(snapshot.ref, 'error', error.message);
    }
  });

/**
 * Helper function to update push notification status in Firestore
 */
async function updatePushNotificationStatus(docRef, status, errorMessage = null, successCount = 0, failureCount = 0, errorDetails = []) {
  try {
    const updateData = {
      status: status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    if (status === 'delivered' || status === 'failed') {
      updateData.successCount = successCount;
      updateData.failureCount = failureCount;
      updateData.sentAt = admin.firestore.FieldValue.serverTimestamp();
    }
    
    if (errorMessage) {
      updateData.error = errorMessage;
    }
    
    if (errorDetails && errorDetails.length > 0) {
      updateData.errorDetails = errorDetails;
    }
    
    await docRef.update(updateData);
    return { success: true };
  } catch (error) {
    console.error('Error updating push notification status:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Helper function to remove invalid token from all users' documents
 */
async function removeInvalidTokenFromAllUsers(invalidToken) {
  try {
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .where('deviceTokens', 'array-contains', invalidToken)
      .get();
    
    if (usersSnapshot.empty) {
      console.log('Token not found in any user documents');
      return false;
    }
    
    const batch = admin.firestore().batch();
    
    usersSnapshot.docs.forEach(doc => {
      batch.update(doc.ref, {
        deviceTokens: admin.firestore.FieldValue.arrayRemove(invalidToken),
        lastTokenUpdate: admin.firestore.FieldValue.serverTimestamp()
      });
    });
    
    await batch.commit();
    console.log(`Removed invalid token from ${usersSnapshot.docs.length} users`);
    return true;
  } catch (error) {
    console.error('Error removing invalid token from users:', error);
    return false;
  }
} 