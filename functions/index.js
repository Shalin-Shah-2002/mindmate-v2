const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
// For runtime config fallback
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function to send push notifications when a notification document is created
 * Triggers on: /notifications/{notificationId}
 */
exports.sendPushNotification = onDocumentCreated(
    "notifications/{notificationId}",
    async (event) => {
      try {
        // Get the notification document data
        if (!event.data) {
          console.log("No document data in event");
          return null;
        }
        const notificationData = event.data.data();
        const notificationId = event.params.notificationId;

        console.log("Processing notification:", notificationId, notificationData);

        // Get the recipient user id (we'll target OneSignal external user id)
        const recipientId = notificationData.recipientId;
        if (!recipientId) {
          console.log("No recipientId found in notification");
          return null;
    }

    // Build OneSignal notification payload
    // Prefer environment variables; fallback to Firebase runtime config.
    // Set via:
    // firebase functions:config:set \
    //   onesignal.app_id="..." onesignal.rest_api_key="..."
    let appId = process.env.ONESIGNAL_APP_ID;
        let apiKey = process.env.ONESIGNAL_REST_API_KEY;
        if (!appId || !apiKey) {
          try {
            const cfg = functions.config();
            if (!appId && cfg && cfg.onesignal && cfg.onesignal.app_id) {
              appId = cfg.onesignal.app_id;
            }
            if (!apiKey && cfg && cfg.onesignal && cfg.onesignal.rest_api_key) {
              apiKey = cfg.onesignal.rest_api_key;
            }
          } catch (e) {
            // functions.config() may not be available in some environments
          }
        }

        if (!appId || !apiKey) {
          console.error("OneSignal env vars not set. Please set ONESIGNAL_APP_ID and ONESIGNAL_REST_API_KEY.");
          return null;
        }

        const payload = {
          app_id: appId,
          include_external_user_ids: [recipientId],
          headings: {en: notificationData.title || "MindMate"},
          contents: {en: notificationData.body || "You have a new notification"},
          data: notificationData.data || {},
        };

        console.log("Sending OneSignal notification to external_user_id:", recipientId);
        const res = await fetch("https://onesignal.com/api/v1/notifications", {
          method: "POST",
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": `Basic ${apiKey}`,
          },
          body: JSON.stringify(payload),
        });

        const text = await res.text();
        if (!res.ok) {
          console.error("OneSignal send failed:", res.status, text);
          return null;
        }
        console.log("OneSignal send success:", text);
        return text;
      } catch (error) {
        console.error("Error sending notification:", error);
        return null;
      }
    },
);

/**
 * Cloud Function to update user's FCM token when they login
 * You can call this from your app after successful authentication
 */
exports.updateFCMToken = onDocumentCreated(
    "users/{userId}",
    async (event) => {
      try {
        const userId = event.params.userId;
        console.log("User created or updated:", userId);

        // You can add any initialization logic here
        // For example, setting up default notification preferences

        return null;
      } catch (error) {
        console.error("Error in updateFCMToken:", error);
        return null;
      }
    },
);

/**
 * Clean up old notifications (optional)
 * Runs daily to delete notifications older than 30 days
 */
exports.cleanupOldNotifications = onSchedule("every 24 hours", async (event) => {
  try {
    const db = admin.firestore();
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const oldNotifications = await db
        .collection("notifications")
        .where("createdAt", "<", thirtyDaysAgo)
        .get();

    const batch = db.batch();
    oldNotifications.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Deleted ${oldNotifications.size} old notifications`);

    return null;
  } catch (error) {
    console.error("Error cleaning up old notifications:", error);
    return null;
  }
});


