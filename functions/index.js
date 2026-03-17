const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

exports.onNewFollower = functions.firestore
  .document('followers/{docId}')
  .onCreate(async (snap) => {
    const { targetUid, followerUid, followerName } = snap.data() || {};
    if (!targetUid || !followerUid) return null;

    const targetDoc = await db.collection('users').doc(targetUid).get();
    const fcmToken = targetDoc.data()?.fcmToken;
    if (!fcmToken) return null;

    return admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'New follower',
        body: `${followerName || 'Someone'} started following you`,
      },
      data: { type: 'follow', fromUid: followerUid },
    });
  });

exports.onPostLike = functions.firestore
  .document('postLikes/{likeId}')
  .onCreate(async (snap) => {
    const { postId, likerUid, likerName } = snap.data() || {};
    if (!postId || !likerUid) return null;

    const postDoc = await db.collection('posts').doc(postId).get();
    const authorId = postDoc.data()?.authorId;
    if (!authorId || authorId === likerUid) return null;

    const authorDoc = await db.collection('users').doc(authorId).get();
    const fcmToken = authorDoc.data()?.fcmToken;
    if (!fcmToken) return null;

    return admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'New like',
        body: `${likerName || 'Someone'} liked your post`,
      },
      data: { type: 'like', postId },
    });
  });

exports.expireStories = functions.pubsub.schedule('every 60 minutes').onRun(async () => {
  const cutoff = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 24 * 60 * 60 * 1000),
  );

  const oldStories = await db
    .collection('stories')
    .where('createdAt', '<', cutoff)
    .get();

  if (oldStories.empty) return null;

  const batch = db.batch();
  oldStories.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  console.log(`Deleted ${oldStories.size} expired stories`);
  return null;
});

exports.segpayWebhook = functions.https.onRequest(async (req, res) => {
  const { transaction_id, customer_email, status } = req.body || {};
  if (status !== 'approved') {
    res.status(200).send('ok');
    return;
  }

  const usersSnap = await db
    .collection('users')
    .where('email', '==', customer_email)
    .limit(1)
    .get();

  if (usersSnap.empty) {
    res.status(200).send('ok');
    return;
  }

  const uid = usersSnap.docs[0].id;
  const pendingSubs = await db
    .collection('subscriptions')
    .where('subscriberId', '==', uid)
    .where('status', '==', 'pending')
    .get();

  const batch = db.batch();
  pendingSubs.docs.forEach((doc) => {
    batch.update(doc.ref, {
      status: 'active',
      segpayTransactionId: transaction_id || '',
      startedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      ),
    });
  });

  await batch.commit();
  res.status(200).send('ok');
});

exports.onNewMessage = functions.firestore
  .document('conversations/{convId}/messages/{msgId}')
  .onCreate(async (snap, context) => {
    const { senderId, text } = snap.data() || {};
    const convId = context.params.convId;
    if (!senderId || !convId) return null;

    const convDoc = await db.collection('conversations').doc(convId).get();
    const participants = convDoc.data()?.participantIds || [];
    const recipientUid = participants.find((id) => id !== senderId);
    if (!recipientUid) return null;

    const recipientDoc = await db.collection('users').doc(recipientUid).get();
    const fcmToken = recipientDoc.data()?.fcmToken;
    if (!fcmToken) return null;

    const senderDoc = await db.collection('users').doc(senderId).get();
    const senderName = senderDoc.data()?.displayName || 'Someone';

    return admin.messaging().send({
      token: fcmToken,
      notification: { title: senderName, body: text || 'New message' },
      data: { type: 'message', convId, fromUid: senderId },
    });
  });
