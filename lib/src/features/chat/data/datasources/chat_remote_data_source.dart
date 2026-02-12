import 'package:chat_app/src/features/chat/data/models/chat_message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;
  static const _conversationCollection = 'conversations';
  static const defaultPageSize = 40;

  Stream<List<ChatMessageModel>> watchMessages({
    required String conversationId,
    int limit = defaultPageSize,
  }) {
    return _firestore
        .collection(_conversationCollection)
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .orderBy('id', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => ChatMessageModel.fromFirestore(doc))
              .toList(growable: false);
          return _sortAscending(messages);
        });
  }

  Future<List<ChatMessageModel>> loadOlderMessages({
    required String conversationId,
    required DateTime beforeCreatedAt,
    required String beforeMessageId,
    int limit = defaultPageSize,
  }) async {
    final snapshot = await _firestore
        .collection(_conversationCollection)
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .orderBy('id', descending: true)
        .startAfter([Timestamp.fromDate(beforeCreatedAt), beforeMessageId])
        .limit(limit)
        .get();

    final messages = snapshot.docs
        .map((doc) => ChatMessageModel.fromFirestore(doc))
        .toList(growable: false);
    return _sortAscending(messages);
  }

  Future<void> sendMessage({
    required String conversationId,
    required ChatMessageModel message,
  }) async {
    final conversationRef = _firestore
        .collection(_conversationCollection)
        .doc(conversationId);
    final messagesRef = conversationRef.collection('messages');
    final docRef = messagesRef.doc(message.id);

    // Ensure conversation metadata exists for rules/queries.
    await conversationRef.set({
      'participants': [message.senderId, message.receiverId]..sort(),
      'lastMessage': message.text,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Use client timestamp for createdAt so the new message appears instantly
    // in the current query; updatedAt still uses server time on conversation.
    await docRef.set(message.toMap(), SetOptions(merge: true));
  }

  List<ChatMessageModel> _sortAscending(List<ChatMessageModel> input) {
    final sorted = List<ChatMessageModel>.of(input);
    sorted.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
    return sorted;
  }
}
