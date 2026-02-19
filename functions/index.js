const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();

const DEFAULT_MESSAGE_BODY = 'New message';
const IMAGE_MESSAGE_BODY = 'Photo';
const DEFAULT_TITLE = 'New message';

exports.notifyOnConversationMessage = onDocumentCreated(
  {
    document: 'conversations/{conversationId}/messages/{messageId}',
    region: 'us-central1',
  },
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    const senderId = String(message.senderId ?? '').trim();
    const receiverId = String(message.receiverId ?? '').trim();
    if (!senderId || !receiverId || senderId === receiverId) return;

    // Chat repo writes compatibility copies; only notify from canonical id.
    const canonicalConversationId = [senderId, receiverId].sort().join('_');
    if (event.params.conversationId !== canonicalConversationId) return;

    const firestore = admin.firestore();
    const users = firestore.collection('users');
    const [senderSnap, receiverSnap] = await Promise.all([
      users.doc(senderId).get(),
      users.doc(receiverId).get(),
    ]);

    if (!receiverSnap.exists) return;
    const receiverData = receiverSnap.data() || {};
    const token = String(receiverData.fcmToken ?? '').trim();
    if (!token) return;

    const senderData = senderSnap.exists ? senderSnap.data() || {} : {};
    const senderName =
      String(senderData.username ?? '').trim() ||
      String(senderData.displayName ?? '').trim() ||
      String(senderData.firstName ?? '').trim() ||
      String(senderData.email ?? '').trim() ||
      DEFAULT_TITLE;

    const text = String(message.text ?? '').trim();
    const hasImage = String(message.imageUrl ?? '').trim().length > 0;
    const body = text || (hasImage ? IMAGE_MESSAGE_BODY : DEFAULT_MESSAGE_BODY);

    const payload = {
      token,
      notification: {
        title: senderName,
        body,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'chat_messages_high_v2',
          priority: 'max',
          sound: 'default',
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
      data: {
        type: 'chat_message',
        conversationId: String(event.params.conversationId),
        messageId: String(event.params.messageId),
        senderId,
        receiverId,
        senderName,
        body,
      },
    };

    try {
      await admin.messaging().send(payload);
    } catch (error) {
      logger.error('Failed to send chat notification', {
        error: String(error),
        receiverId,
        messageId: event.params.messageId,
      });
    }
  },
);
