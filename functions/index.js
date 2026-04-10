const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

// Set global options to us-central1 (or your preferred region)
setGlobalOptions({ region: "us-central1" });

/**
 * Triggers when a new club announcement is created (2nd Gen).
 * Sends a real push notification to the relevant FCM topic.
 */
exports.sendAnnouncementPush = onDocumentCreated("club_announcements/{docId}", async (event) => {
  const data = event.data.data();
  if (!data) return;

  const title = data.title || "New Announcement";
  const message = data.message || "";
  const target = data.target;
  const eventId = data.eventId;

  let topic = "broadcast_all"; // Default to broadcast
  if (target === "event_participants" && eventId) {
    topic = `event_${eventId}`;
  }

  const payload = {
    notification: {
      title: title,
      body: message,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      screen: "announcement",
      eventId: eventId || "",
      type: "announcement",
    },
    topic: topic,
  };

  try {
    const response = await admin.messaging().send(payload);
    console.log(`Successfully sent message to topic ${topic}:`, response);
    return response;
  } catch (error) {
    console.error(`Error sending message to topic ${topic}:`, error);
    return null;
  }
});

/**
 * Triggers when a notification is added to a specific user (2nd Gen).
 */
exports.sendUserPush = onDocumentCreated("notifications/{docId}", async (event) => {
    // Note: Direct user push implementation can go here if needed
    return null;
});
