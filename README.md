# chat_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

## Project docs

- MVP starter blueprint: `docs/mvp_starter_blueprint.md`
- Architecture notes: `docs/architecture.md`
- Firestore rules skeleton: `firestore.rules`

## Push Notifications (App Closed)

Offline notifications require server-side FCM sending. This repo includes
`functions/index.js` trigger:

- Trigger: `conversations/{conversationId}/messages/{messageId}`
- Action: sends FCM to `users/{receiverId}.fcmToken`
- Duplicate protection: sends only for canonical `conversationId`

Deploy steps:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
