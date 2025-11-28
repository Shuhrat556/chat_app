import 'package:chat_app/src/features/chat/data/models/chat_message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;
  static const _conversationCollection = 'conversations';

  Stream<List<ChatMessageModel>> watchMessages({
    required String conversationId,
  }) {
    return _firestore
        .collection(_conversationCollection)
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessageModel.fromFirestore(doc))
              .toList(growable: false),
        );
  }

  Future<void> sendMessage({
    required String conversationId,
    required ChatMessageModel message,
  }) async {
    final conversationRef = _firestore.collection(_conversationCollection).doc(conversationId);
    final messagesRef = conversationRef.collection('messages');
    final docRef = messagesRef.doc(message.id);

    // Ensure conversation metadata exists for rules/queries.
    await conversationRef.set(
      {
        'participants': [message.senderId, message.receiverId]..sort(),
        'lastMessage': message.text,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await docRef.set(
      message.toMap(useServerTimestamp: true),
      SetOptions(merge: true),
    );
  }
}
