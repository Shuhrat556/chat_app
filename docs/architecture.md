# Chat App - Clean Architecture

## Qisqacha
- Flutter ilova, backend sifatida Firebase: Auth, Firestore, Storage, Cloud Messaging, Cloud Functions (SMS yuborish uchun ko'prik), App Check.
- State management: Bloc + flutter_bloc. DI: get_it/riverpod_service_locator. Routing: go_router.
- Mahalliy kesh: Isar (foydalanuvchi, chat, xabar, sozlama, media metadata).
- Maqsad: offline-first chat tajribasi, push/sms xabarnomalari, profil boshqaruvi, sozlanadigan notification.

## Layerlar (Clean Architecture)
- presentation: UI, Bloc/Cubit, view-model mapperlar. Har feature uchun `view`, `bloc`, `widgets`.
- domain: entity va value objectlar, usecase/interactorlar, repository interfeyslari, validatorlar.
- data: repository implementatsiyalari, remote datasource (Firebase), local datasource (Isar), DTO va mapperlar.
- core/common: di registratsiya, error/result wrappers, logger, analytics, network/status checker, device info, file picker adapter.
- entry: `bootstrap.dart` (firebase init, di init), `app.dart` (router, theme, localization, MediaQuery).

## Tavsiya etilgan papkalar
```
lib/
  src/
    app.dart
    bootstrap.dart
    core/
      di/locator.dart
      error/failure.dart
      network/connection_observer.dart
      notification/push_initializer.dart
      utils/date_formatter.dart
    data/
      datasources/
        remote/firebase_auth_ds.dart
        remote/firestore_chat_ds.dart
        remote/storage_avatar_ds.dart
        remote/functions_sms_ds.dart
        local/isar_chat_ds.dart
      dto/
      mappers/
      repositories_impl/
    domain/
      entities/
      value_objects/
      repositories/
      usecases/
    features/
      auth/...
      chat/...
      contacts/...
      profile/...
      settings/...
      notifications/...
      search/...
```

## Data model (asosiy)
- UserEntity: id, username, email, avatarUrl, phone, status(online/lastSeen), about, notificationEnabled, fcmToken, createdAt.
- ChatEntity: id, isGroup, title, members, lastMessage, unreadCount, pinned, mutedUntil.
- MessageEntity: id, chatId, fromUserId, text/body, attachments, status(sent, delivered, read), replyTo, createdAt, editedAt, deletedAt, reactions.
- SettingsEntity: notificationEnabled, smsFallbackEnabled, language, theme, privacy(lastSeen, avatar visibility), blockedIds.

## Remote qatlam (Firebase)
- Auth: email+password ro'yxatdan o'tkazish, username Firestore `users` hujjatida saqlanadi (unique check Cloud Function bilan).
- Firestore:
  - `users/{userId}`
  - `chats/{chatId}` (meta)
  - `chats/{chatId}/messages/{messageId}`
  - `presence/{userId}` (online/last seen)
  - `settings/{userId}` (notification toggles, sms fallback)
- Storage: avatar rasmlari, media preview.
- Cloud Messaging: push token saqlash, foreground/background handle.
- Cloud Functions:
  - Username uniqueness va normalization.
  - SMS fallback trigger: yangi xabar kelganda qabul qiluvchi push o'chirilgan bo'lsa yoki offline bo'lsa SMS yuborish.
  - Notification payload enrich (chat title, sender).

## Local qatlam (Isar)
- Kesh: foydalanuvchi profili, chat list, xabarlar, sozlamalar, media metadata.
- Strategy: app ochilganda Isar snapshot, keyin Firestore stream bilan difflarni qo'shish/yangilash.
- Offline: jo'natilmagan xabarlar queue (Isar) + background retry (connectivity listener).

## State/oqimlar
- Auth flow: onboard -> sign up (username, email, parol) -> email verify optional -> profil sozlash -> chat list.
- Chat list: Isar snapshot -> Firestore stream -> Bloc state (loading, ready, error). UnreadCount lokal hisoblanadi.
- Chat screen: message stream, typing indicator, send action -> local append -> remote send -> status update (sent/delivered/read).
- Settings: toggle push/sms, mute chat, privacy, theme. Sync Firestore + Isar.
- Notification handler: background push -> local notification plugin -> tap opens route. Respect `notificationEnabled` va chat mute.

## Navigatsiya
- go_router declarative marshrutlar: `/`, `/auth`, `/chats`, `/chats/:id`, `/profile`, `/settings`, `/search`, `/contacts`.
- Deep link/push open uchun route parser.

## Qo'shimcha funksiyalar
- Message reactions, reply/thread, edit/delete, pin chat, search (messages/users), block/mute, read receipts, typing indicator, last seen/presence, media upload/download progress, avatar crop/compress, app lock (PIN/Biometrics), multi-language (uz/ru/en), theming (light/dark/system).

## Sinov va sifat
- Unit: usecase, mapper, repository mock bilan.
- Widget test: Bloc + golden asosiy ekranlar.
- Integration: Firebase emulator set + offline/online sync.
- Monitoring: Crashlytics, analytics eventlar.
