// Firebase Cloud Messaging notification service
// NOTE: Requires Firebase Admin SDK configuration
// Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY in .env

let admin = null;

try {
  const firebaseAdmin = require('firebase-admin');
  
  if (process.env.FIREBASE_PROJECT_ID) {
    admin = firebaseAdmin;
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      }),
    });
    console.log('✅ Firebase Admin initialized');
  } else {
    console.log('⚠️  Firebase not configured — push notifications disabled');
  }
} catch (error) {
  console.log('⚠️  Firebase initialization failed:', error.message);
}

/**
 * Send push notification to a user
 */
async function sendNotification(fcmToken, title, body, data = {}) {
  if (!admin || !fcmToken) return null;

  try {
    const message = {
      token: fcmToken,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: 'high',
        notification: { channelId: 'attendance' },
      },
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 },
        },
      },
    };

    const response = await admin.messaging().send(message);
    return response;
  } catch (error) {
    console.error('Failed to send notification:', error.message);
    return null;
  }
}

/**
 * Send notification to multiple users
 */
async function sendMultipleNotifications(tokens, title, body, data = {}) {
  if (!admin || !tokens.length) return null;

  const validTokens = tokens.filter(Boolean);
  if (!validTokens.length) return null;

  try {
    const message = {
      tokens: validTokens,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    return response;
  } catch (error) {
    console.error('Failed to send notifications:', error.message);
    return null;
  }
}

module.exports = { sendNotification, sendMultipleNotifications };
