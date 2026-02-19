import 'package:chat_app/src/features/chat/data/models/chat_message_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ttlSeconds and expireAt are serialized/deserialized', () async {
    final firestore = FakeFirebaseFirestore();
    final createdAt = DateTime.now();
    final expireAt = createdAt.add(const Duration(seconds: 30));
    const conversationId = 'u1_u2';
    const messageId = 'm1';

    final message = ChatMessageModel(
      id: messageId,
      conversationId: conversationId,
      senderId: 'u1',
      receiverId: 'u2',
      text: 'hello',
      createdAt: createdAt,
      ttlSeconds: 30,
      expireAt: expireAt,
      deletedForAll: false,
    );

    await firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());

    final snapshot = await firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .get();
    final parsed = ChatMessageModel.fromFirestore(snapshot);

    expect(parsed.ttlSeconds, 30);
    expect(parsed.deletedForAll, false);
    expect(parsed.expireAt, isNotNull);
    expect(
      parsed.expireAt!.difference(expireAt).inSeconds.abs(),
      lessThanOrEqualTo(1),
    );
  });
}
