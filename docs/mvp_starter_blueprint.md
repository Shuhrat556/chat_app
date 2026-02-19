# Chat App MVP Starter Blueprint

Bu hujjat siz bergan yakuniy talablar asosida start qilish uchun tayyor texnik baza.

## 1) Locked Requirements

- Username: `5-20`, faqat lotin harflari (`A-Z`, `a-z`).
- Secret chat timer: user o'zi tanlaydi, default holat `ON`.
- Read receipts: user `ON/OFF` qilishi mumkin.
- Sticker pack: har user faqat `1` ta pack qo'sha oladi.

## 2) Dependencies (`pubspec.yaml`)

Qo'shilgan paketlar:

- `file_picker`
- `video_compress`
- `record`
- `flutter_webrtc`
- `cryptography`

Mavjud Firebase/BLoC bazasi saqlab qolindi.

## 3) Flutter Structure (incremental)

Loyiha hozir `lib/src/...` formatda. Shu sababli birdan to'liq ko'chirish o'rniga, yangi featurelarni shu pattern bo'yicha qo'shish tavsiya qilinadi:

```text
lib/src/features/
  auth/
  profile/
  chats/
  chat_room/
  calls/
  settings/
lib/src/core/
  services/
    encryption_service.dart
    fcm_service.dart
```

## 4) Firestore Schema (MVP)

```text
users/{uid}
  username
  displayName
  photoURL
  createdAt
  settings:
    readReceipts: bool
    secretChatDefaultOn: bool
  publicKey

usernames/{username}
  uid
  createdAt

directChats/{chatId}
  members: [uid1, uid2]
  createdAt
  lastMessageAt
  lastMessageMeta: {type, senderId, createdAt}

directChats/{chatId}/members/{uid}
  lastReadAt
  lastReadMessageId
  mutedUntil

directChats/{chatId}/messages/{messageId}
  senderId
  type
  encryptedPayload
  nonce
  attachmentsMeta
  replyTo
  forwardedFrom
  reactions
  createdAt
  editedAt
  deletedForAll
  ttlSeconds
  expireAt

stickers/{uid}
  title
  createdAt
  itemsCount
  items: [{id, url, createdAt}]
```

## 5) Deterministic Chat ID

```dart
String directChatId(String a, String b) {
  final pair = [a, b]..sort();
  return '${pair[0]}_${pair[1]}';
}
```

Bu duplicate 1-1 chatlarni oldini oladi.

## 6) Read Receipt Logic

- `sent`: message Firestore'ga yozildi.
- `read`: `directChats/{chatId}/members/{uid}.lastReadMessageId` orqali aniqlanadi.
- Agar receiver `readReceipts=false` bo'lsa, sender UI'da read status ko'rsatilmaydi.

## 7) Secret Timer Strategy

- User timer tanlaydi (`ttlSeconds`).
- Message yozilganda `expireAt` hisoblab qo'yiladi.
- Cloud Function expire bo'lgan xabarlarni:
  - `deletedForAll=true`
  - `encryptedPayload=""`
  qilib yangilaydi (MVP audit-safe yondashuv).

## 8) E2EE MVP (tez va amaliy)

- User keypair: `X25519`.
- `users/{uid}` da public key saqlanadi.
- Private key qurilmada secure storage'da.
- Chatda ECDH orqali shared secret olinadi.
- HKDF -> AES key.
- Message: `AES-GCM` bilan shifrlanadi.

## 9) WebRTC Signaling (Firestore)

```text
calls/{callId}
  state: ringing/accepted/ended/missed
  participants
  offer
  answer

calls/{callId}/ice/{uid}/candidates/{candId}
  candidate payload
```

Flow:

1. Caller `offer` yozadi (`ringing`).
2. Callee `offer`ni olib `answer` yozadi.
3. Har ikki tomon ICE candidate yozadi/o'qiydi.
4. Tugaganda `state=ended`.

## 10) Firestore Rules

MVP skeleton `firestore.rules` fayliga yozildi.
Unda quyidagilar bor:

- `isLatinUsername`: username format check (`5-20`, latin).
- Chat read/write faqat memberlarga.
- Message create faqat sender o'zi uchun.
- Sticker pack create faqat owner va bitta pack.

## 11) Build Order (Sprint)

1. Firebase init + Auth (email/google/apple)
2. Username transaction (`usernames/{username}`)
3. Chat list + create by username
4. Chat send/receive text
5. E2EE layer
6. Media/voice
7. Calls (voice/video + signaling)
8. Secret timer cleanup function
9. Sticker pack (1 per user)

