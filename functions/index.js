const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// AUTO SEND NOTIFICATION WHEN ANNOUNCEMENT CREATED
exports.sendAnnouncementNotification = functions.firestore
  .document("announcements/{id}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    const title = data.title || "New Announcement";
    const body = data.body || "";
    const target = data.target || "ALL";

    let tokens = [];

    // Fetch target users
    let usersQuery = admin.firestore().collection("users");

    if (target !== "ALL") {
      usersQuery = usersQuery.where("role", "in", target);
    }

    const usersSnapshot = await usersQuery.get();

    usersSnapshot.forEach((user) => {
      if (user.data().fcmToken) {
        tokens.push(user.data().fcmToken);
      }
    });

    if (tokens.length === 0) {
      console.log("No FCM tokens found.");
      return null;
    }

    const payload = {
      notification: {
        title: title,
        body: body,
      },
      tokens: tokens,
    };

    return admin.messaging().sendMulticast(payload);
  });
