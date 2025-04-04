const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Max batch size for FCM is 500
const FCM_BATCH_SIZE = 500;

/**
 * Cloud Function that triggers when a new notification document is created in Firestore.
 * It sends push notifications to the specified device tokens using Firebase Cloud Messaging.
 */
exports.sendNotificationOnCreate = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    try {
      const notificationId = context.params.notificationId;
      const notificationData = snapshot.data();
      
      console.log(`Processing notification ${notificationId} of type ${notificationData.type}`);
      
      // Only process notifications of type 'blood_request_response'
      if (notificationData.type !== 'blood_request_response') {
        console.log('Skipping notification - not a blood request response');
        return null;
      }
      
      const userId = notificationData.userId;
      
      // Get user document to check notification preferences
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        console.error(`User document for user ${userId} not found`);
        return await updateNotificationStatus(snapshot.ref, 'error', 'User document not found');
      }
      
      const userData = userDoc.data();
      
      // Check if user has enabled notifications
      const notificationsEnabled = userData.notificationsEnabled !== false; // Default to true if not specified
      if (!notificationsEnabled) {
        console.log(`User ${userId} has disabled notifications`);
        return await updateNotificationStatus(snapshot.ref, 'skipped', 'User has disabled notifications');
      }
      
      // Get user device tokens
      const deviceTokens = userData.deviceTokens || [];
      
      // Process result stats
      let totalSuccess = 0;
      let totalFailure = 0;
      let errorDetails = [];
      
      // Try direct device notification first
      if (deviceTokens.length > 0) {
        console.log(`Found ${deviceTokens.length} device tokens for user ${userId}`);
        
        // Process in batches of FCM_BATCH_SIZE for better performance and reliability
        for (let i = 0; i < deviceTokens.length; i += FCM_BATCH_SIZE) {
          const batch = deviceTokens.slice(i, i + FCM_BATCH_SIZE);
          
          // Create rich notification payload
          const message = {
            notification: {
              title: notificationData.title || 'Blood Donation Request Response',
              body: notificationData.body || `${notificationData.responderName} has responded to your blood request`,
              // Add notification channel for Android
              android_channel_id: 'blood_donation_high_importance',
            },
            data: {
              type: 'blood_request_response',
              requestId: notificationData.requestId || '',
              responderName: notificationData.responderName || '',
              responderPhone: notificationData.responderPhone || '',
              bloodType: notificationData.bloodType || '',
              responderId: notificationData.responderId || '',
              timestamp: Date.now().toString(),
              notification_id: notificationId,
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
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
            tokens: batch,
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
                  const token = batch[idx];
                  const error = resp.error.toJSON();
                  console.error(`Error sending to token ${token.substr(0, 10)}...: ${error.code}`, error);
                  
                  errorDetails.push({
                    token: token.substr(0, 10) + '...',
                    code: error.code,
                    message: error.message
                  });
                  
                  // If token is invalid, remove it from user's tokens
                  if (error.code === 'messaging/invalid-registration-token' || 
                      error.code === 'messaging/registration-token-not-registered') {
                    removeInvalidToken(userId, token);
                  }
                }
              });
            }
          } catch (error) {
            console.error('Error sending batch:', error);
            errorDetails.push({
              batch: `Batch ${i/FCM_BATCH_SIZE + 1}`,
              code: error.code || 'unknown',
              message: error.message
            });
          }
        }
      } else {
        console.log(`No device tokens found for user ${userId}, trying topic notifications as fallback`);
        
        // As a fallback, try sending to a user-specific topic
        try {
          // Create a user-specific topic using their ID
          const userTopic = `user_${userId}`;
          
          const message = {
            topic: userTopic,
            notification: {
              title: notificationData.title || 'Blood Donation Request Response',
              body: notificationData.body || `${notificationData.responderName} has responded to your blood request`,
            },
            data: {
              type: 'blood_request_response',
              requestId: notificationData.requestId || '',
              responderName: notificationData.responderName || '',
              responderPhone: notificationData.responderPhone || '',
              bloodType: notificationData.bloodType || '',
              responderId: notificationData.responderId || '',
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
              priority: 'high',
              notification: {
                sound: 'default',
                priority: 'max',
              }
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1
                }
              }
            }
          };
          
          const response = await admin.messaging().send(message);
          console.log(`Sent topic message to ${userTopic}, messageId: ${response}`);
          totalSuccess = 1; // Count as a success
        } catch (error) {
          console.error('Error sending topic notification:', error);
          totalFailure = 1;
          errorDetails.push({
            method: 'topic',
            code: error.code || 'unknown',
            message: error.message
          });
        }
      }
      
      // Update notification document with delivery status
      const status = totalSuccess > 0 ? 'delivered' : 'failed';
      await updateNotificationStatus(snapshot.ref, status, null, totalSuccess, totalFailure, errorDetails);
      
      // Log final results
      console.log(`Notification ${notificationId} processed with status ${status}: ${totalSuccess} successful, ${totalFailure} failed`);
      
      return { success: (totalSuccess > 0), successCount: totalSuccess, failureCount: totalFailure };
    } catch (error) {
      console.error('Unhandled error processing notification:', error);
      return await updateNotificationStatus(snapshot.ref, 'error', error.message);
    }
  });

/**
 * Helper function to update notification status in Firestore
 */
async function updateNotificationStatus(docRef, status, errorMessage = null, successCount = 0, failureCount = 0, errorDetails = []) {
  try {
    const updateData = {
      deliveryStatus: {
        status: status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }
    };
    
    if (status === 'delivered' || status === 'failed') {
      updateData.deliveryStatus.successCount = successCount;
      updateData.deliveryStatus.failureCount = failureCount;
      updateData.deliveryStatus.sentAt = admin.firestore.FieldValue.serverTimestamp();
    }
    
    if (errorMessage) {
      updateData.deliveryStatus.error = errorMessage;
    }
    
    if (errorDetails && errorDetails.length > 0) {
      updateData.deliveryStatus.errorDetails = errorDetails;
    }
    
    await docRef.update(updateData);
    return { success: true };
  } catch (error) {
    console.error('Error updating notification status:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Helper function to remove invalid tokens from a user's document
 */
async function removeInvalidToken(userId, invalidToken) {
  try {
    await admin.firestore().collection('users').doc(userId).update({
      deviceTokens: admin.firestore.FieldValue.arrayRemove(invalidToken),
      lastTokenUpdate: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log(`Removed invalid token for user ${userId}`);
    return true;
  } catch (error) {
    console.error('Error removing invalid token:', error);
    return false;
  }
}
