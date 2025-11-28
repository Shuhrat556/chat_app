# Texnik topshiriq (TZ) - Chat App

## Maqsad
Firebase bilan ulangan, offline-first chat ilovasi. Foydalanuvchi email+parol+username bilan ro'yxatdan o'tadi, real vaqt xabarlar, push va sms xabarnoma, profil va sozlama boshqaruvi mavjud.

## Qamrov
- Platforma: Flutter (Android/iOS/Web). Backend: Firebase (Auth, Firestore, Storage, Cloud Functions, FCM). Lokal: Isar. State: Bloc.

## Funktsional talablar
- Ro'yxatdan o'tish: username (unikal), email, parol. Username validatsiya va unikallikni Cloud Function tekshiradi.
- Kirish/chiqish: email+parol login, parol tiklash (email), logout barcha sessiyalardan.
- Foydalanuvchi profili: avatar yuklash/yangilash, about/bio, telefon raqam (sms fallback uchun), status (online/last seen).
- Kontaktlar/foydalanuvchilar ro'yxati: Firestore `users` dan barcha mavjud foydalanuvchilarni ko'rsatish, qidirish (username, email). Block/mute funksiyasi.
- Chatlar: 1-1 chatlar (default). Keyinchalik group chatlarni qo'shish uchun API tayyor qoldirish (isGroup flag).
- Chat ro'yxati: so'nggi xabar, unread count, pin/mute status, typing indicator preview, oxirgi xabar vaqtini ko'rsatish.
- Xabar yuborish/qabul qilish: matn, emoji, reply, edit/delete (soft delete), reactions, read receipts (sent/delivered/read), typing indicator, attachments (rasm/video/voice) metadata bilan.
- Offline: yuborilgan xabar queue'da saqlanadi, ulanish tiklanganda avtomatik jo'natish. Keshdan chat va xabarlarni ko'rsatish.
- Bildirishnoma: push (FCM) foreground/background/terminated holatlarda. Har chatni mute qilish, umumiy notification toggle. Badge va sound sozlamalari.
- SMS fallback: foydalanuvchida push o'chirilgan/offline bo'lsa yangi xabar haqida SMS yuborish (Cloud Function + third-party gateway). Sozlamadan yoqish/o'chirish.
- Sozlamalar: notification on/off, sms fallback on/off, til (uz/ru/en), tema (light/dark/system), privacy (last seen ko'rinishi, avatar ko'rinishi), blocked users ro'yxati.
- Qidiruv: chatlar va xabarlar bo'yicha matnli qidiruv (Firestore + lokal index).
- Media: avatar/attachment upload (Storage), preview url, progress indikatsiyasi, download/ko'rish.
- Navigatsiya: onboarding -> auth -> chat list -> chat -> profil/sozlamalar. Push/SMS linklaridan deep link ochish.

## Nofunktsional talablar
- Offline-first: barcha asosiy ekranlar Isar keshdan tez ochilishi, stream bilan sinxronlash.
- Ishlash: chat list <200ms, chat ochilishi <400ms (kesh mavjud bo'lsa), rasm/vid upload progress ko'rsatilishi.
- Xavfsizlik: App Check, Firebase Security Rules (per user access), token refresh, parol siyosati (min 8, harf+raqam). TLS majburiy.
- Monitoring: Crashlytics, logger (file/remote optional), minimal analytics (screen_view, message_send).

## Ma'lumotlar va kolleksiyalar
- `users/{userId}`: username, email, avatarUrl, phone, about, fcmToken, notificationEnabled, smsFallbackEnabled, blockedIds[], lastSeen/online.
- `chats/{chatId}`: isGroup, title, members[], createdAt, lastMessage, pinnedBy[], mutedBy[].
- `chats/{chatId}/messages/{messageId}`: fromUserId, text, attachments[], replyTo, status, reactions[], createdAt, editedAt, deletedAt.
- `presence/{userId}`: online, lastSeen.
- `settings/{userId}`: notificationEnabled, smsFallbackEnabled, theme, language, privacy.
- Isar sxema: local ekvivalentlari + send queue (pending messages).

## Oqimlar
- App start: bootstrap -> Firebase init -> di -> Isar ochish -> auth check -> keshdan chat list -> Firestore stream subscribe -> diff apply.
- Send message: UI -> Bloc -> usecase -> Isar queue write -> remote send -> status update -> Isar update -> UI state.
- Notification: FCM init -> token saqlash -> onMessage: local notification + Isar update; onBackground tap: deep link -> router.
- SMS fallback: Cloud Function trigger on new message -> receiver setting check -> SMS gateway -> deliver status log.

## Sinov
- Unit: usecase, repository interfeys, mapper.
- Widget: auth screen, chat list, chat detail (Bloc test + golden).
- Integration: Firebase emulator (auth/firestore/functions) + offline/online sync, notification handler.

## Qabul mezonlari
- Auth va login ishlaydi, username unikalligi saqlanadi.
- Chat list/xabarlar offline ochiladi, ulanishda sinxronlashadi.
- Push on/off va chat mute ishlaydi; SMS fallback sozlamaga bog'liq.
- Profil avatar yuklanadi va yangilanadi; foydalanuvchilar ro'yxati ko'rinadi.
- Har bir talablarga mos testlar ishlaydi va build o'tadi.




1. Extra Modern Features (Product-Level Upgrades)
1.1. Message & Media

Disappearing messages

Per-chat setting: messages auto-delete after 24h / 7d / 30d.

Local flag in ChatEntity: ephemeralPolicy (none, 24h, 7d, custom).

Cloud Function cleanup + client-side Isar cleanup job.

Draft messages per chat

Store unfinished input locally in Isar (or simple key-value cache) keyed by chatId.

Sync only locally (no need to push drafts to Firestore).

Starred / bookmarked messages

Local + remote flag: starredBy[] in Message.

Separate screen: “Starred messages” by chat.

Advanced media gallery

Per chat: gallery tab that shows only media (images, videos, docs).

Local-indexed Isar collection MediaEntity with relations to messages.

1.2. Social / UX Features

Username @mentions

In group chats later, but you can design now.

Autocomplete popup on “@” + username.

Mentions indexing for “Mentions” filter in chat.

In-app link previews

For URLs in messages: fetch metadata (title, description, image).

Cache preview in Firestore linkPreview field, plus local Isar.

Use a background Cloud Function or client-side link_preview-style package.

Rich text / markdown-lite

Simple syntax: *bold*, _italic_, ~strikethrough~.

Render on UI layer using flutter_markdown (or custom TextSpan parser).

Message forwarding

Select messages → forward to another chat.

UI-level only; Firestore just creates new messages with forwardedFrom metadata.

1.3. Security & Privacy

End-to-end encryption (E2EE) – optional but very modern

Use libs like cryptography or webcrypto for key generation & AES/GCM.

Store:

Encrypted body in Firestore.

Keys locally in secure storage (flutter_secure_storage).

Don’t store plaintext message in Firestore / Isar (only encrypted).

Complex, but a huge plus for “pro” feeling.

Screenshot / screen recording hints (Android/iOS)

On sensitive chats: allow user to enable “sensitive chat mode”.

On Android: set FLAG_SECURE to prevent screenshots.

On iOS: you can’t block, but can detect & show warning in some cases.

Privacy presets

Predefined privacy levels: “Open”, “Friends only”, “Private”.

Map them to:

lastSeen visibility

avatar visibility

read receipts enabled/disabled.

1.4. Growth & Remote Control

Feature flags & remote config

Use Firebase Remote Config to:

Roll out new features gradually (e.g., group chats beta).

Enable/disable experimental features without new deploy.

In-app announcements

Simple “What’s new” banner on the home screen fed from:

Firestore collection announcements scoped by version or segment.

Can be combined with Remote Config / A/B testing.

2. Architecture Upgrades (Still Clean, Just More Mature)

Keep your layers, but add some modern touches.

2.1. Module-Level Organization

Right now you have:

core/
data/
domain/
features/


You can go “feature-first + vertical slicing” like:

lib/
  src/
    core/        // truly shared cross-cutting
    features/
      auth/
        presentation/
        domain/
        data/
      chat/
        presentation/
        domain/
        data/
      profile/
      settings/
      notifications/
      search/


Each feature has its own mini clean-architecture stack.

core/ keeps only generic stuff: error handling, theming, analytics, DI, network, etc.

This scales better as the project grows and makes each feature more testable & incremental.

2.2. Use Cases + Reactive Streams

You already have use cases. Add some “direction” rules:

Command vs Query use cases

SendMessageUseCase, UpdateProfileUseCase → commands (write).

WatchChatMessagesUseCase, WatchChatListUseCase → queries (streams of entities).

Return:

For write: Future<Result<void>>.

For streams: Stream<Result<T>> wrapped in Bloc.

This is close to a lightweight CQRS pattern, but without overkill.

2.3. Design System & Theming Layer

Create a small design system so UI is consistent:

core/
  ui/
    theme/
      app_theme.dart   // theme data + extensions
      color_schemes.dart
      typography.dart
      spacing.dart
    widgets/
      app_button.dart
      app_text_field.dart
      app_avatar.dart
      app_scaffold.dart


Define:

AppColors, AppTypography, AppSpacing, AppRadius, AppDurations.

Use ThemeExtensions to inject design tokens into the theme.

This makes later redesigns much easier.

3. Recommended Packages (Modern Flutter Stack)

Here are some battle-tested packages that fit your architecture nicely.
(Note: names only – you’ll check versions in pub.dev when adding.)

3.1. Core & Architecture

flutter_bloc – you already use it; keep it for presentation.

equatable – for == on entities, state classes.

get_it or riverpod (you mentioned both options):

If you stick to Bloc, get_it or injectable for DI is fine.

If you ever migrate to Riverpod, you can drop get_it.

freezed + json_serializable

For immutable classes + sealed unions (great for bloc states, failures, DTOs).

Removes boilerplate and is very modern.

dartz or your own Result type:

Keep errors functional: Either<Failure, T> or a custom Result<T>.

very_good_analysis or lint

Opinionated, modern lints for clean code style.

3.2. Firebase & Auth

Official / common packages:

firebase_core

firebase_auth

cloud_firestore

firebase_storage

firebase_messaging

firebase_crashlytics

firebase_analytics

firebase_remote_config

cloud_functions

Plus:

flutter_local_notifications for local notifications handling FCM payloads.

flutter_secure_storage for secure tokens / encryption keys.

3.3. Local Storage & Caching

You already chose Isar, which is great.

Add:

isar + isar_flutter_libs – main database.

For small preferences (e.g., UI flags, onboarding completed):

shared_preferences or flutter_secure_storage (if sensitive).

3.4. UI / UX

go_router – as you planned, perfect for deep links & guarded routes.

intl – localization / date formatting, multi-language.

flutter_markdown – rich text rendering for message body / about section.

cached_network_image – avatar & media thumbnails caching.

photo_view – media full screen zoom.

image_cropper / image_picker – avatar & media selection.

lottie – small animations for empty states, onboarding, loading.

3.5. Background Work & Connectivity

connectivity_plus – to observe network status and trigger retries.

workmanager or flutter_background_service

For sending queued messages in the background when connection is back (Android-friendly).

iOS is more limited, but you can still handle when app is brought to foreground.

3.6. Dev Experience & Testing

mocktail – mocking for tests (nicer than mockito imo).

bloc_test – for bloc-specific tests.

integration_test – Flutter official integration testing.

golden_toolkit – for golden tests on UI.

Script / tool suggestions:

Use Melos for workspace management if you split into packages.

Use Fastlane or CI (GitHub Actions, Codemagic) for release builds.

4. Extra Architectural Patterns
4.1. Analytics as a separate layer

Add:

core/
  analytics/
    analytics_service.dart
    analytics_event.dart


Don’t call Firebase Analytics directly from blocs.

Instead, inject AnalyticsService into blocs/usecases and call e.g.:

analytics.logMessageSent(chatId, hasAttachment).

This keeps analytics decoupled from Firebase.

4.2. Logging & Error Handling

Global AppLogger in core/logger.

Bloc observer that logs state transitions (only in debug).

Map technical errors to user-friendly messages in presentation layer.

4.3. Environment Config

Support multiple environments using flavors:

lib/src/core/config/
  app_config.dart   // base config model
  env_config_dev.dart
  env_config_prod.dart


Includes:

API endpoints (if you add non-Firebase services),

Sentry/Crashlytics keys,

Feature flag defaults.

5. Example Refined Folder Structure

Putting everything together:

lib/
  src/
    app.dart
    bootstrap.dart

    core/
      di/
        locator.dart
      config/
        app_config.dart
      error/
        failure.dart
        result.dart
      network/
        connection_observer.dart
      notification/
        push_initializer.dart
      analytics/
        analytics_service.dart
      logger/
        app_logger.dart
      ui/
        theme/
          app_theme.dart
          color_schemes.dart
          typography.dart
          spacing.dart
        widgets/
          app_button.dart
          app_text_field.dart
          app_avatar.dart
      utils/
        date_formatter.dart

    features/
      auth/
        presentation/
          bloc/
          pages/
          widgets/
        domain/
          entities/
          value_objects/
          repositories/
          usecases/
        data/
          datasources/
          dto/
          mappers/
          repositories_impl/

      chat/
        presentation/
        domain/
        data/

      profile/
        ...
      settings/
        ...
      notifications/
        ...
      search/
        ...
      contacts/
        ...


This structure is very “2025 enterprise Flutter” friendly and still understandable.