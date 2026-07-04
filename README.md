# PopPang-Flutter

PopPang-Flutter is the shared Flutter feature repository for PopPang native apps.

The first target feature is the popup admin page, replacing the current native admin UI on iOS and Android with a single shared Flutter implementation.

This repository is not an app-level replacement for PopPang. It is a feature platform that native hosts can embed and route into.

## Goals

- Build the popup admin page once in Flutter and reuse it in both iOS and Android.
- Keep native apps as the owners of app session, app navigation, native SDKs, and release orchestration.
- Treat Flutter as a reusable feature layer so additional feature views can be added later with the same host contract.
- Standardize how native apps launch Flutter features, pass session context, and receive results.

## Non-goals

- Replacing the full PopPang app with Flutter.
- Moving app root navigation ownership from native to Flutter.
- Redesigning current backend auth or API contracts in the first migration.
- Migrating every PopPang feature to Flutter immediately.

## First Feature

The first Flutter feature is:

- `admin.popup_management`

This feature covers:

- popup submission list
- filter state
- popup submission detail
- approve / reject actions
- refresh after moderation completion

From the native app point of view, this is one feature entry.

Inside Flutter, this feature may contain multiple internal screens and its own internal routing flow.

## Platform Model

PopPang-Flutter is consumed by native apps through a shared host contract.

Conceptually:

```text
Native App
├─ App / Root Navigation / Session Owner
├─ Native Features
└─ FlutterFeatureHost
   ├─ featureId = admin.popup_management
   ├─ featureId = review.management           (future)
   ├─ featureId = campaign.editor             (future)
   └─ featureId = ...
```

This means:

- Flutter is one feature platform inside the app.
- Native still owns app-level navigation and session.
- Flutter owns feature-level UI and internal flow.

## Repository Structure

Recommended target structure:

```text
PopPang-Flutter
├─ lib/
│  ├─ app/
│  │  └─ hosted_entry/
│  ├─ contract/
│  │  ├─ host_contract.dart
│  │  ├─ session_snapshot.dart
│  │  ├─ feature_entry_payload.dart
│  │  └─ flutter_feature_event.dart
│  ├─ features/
│  │  ├─ admin_popup_management/
│  │  └─ ...
│  ├─ host_bridge/
│  │  ├─ session_bridge.dart
│  │  ├─ api_gateway.dart
│  │  ├─ navigation_bridge.dart
│  │  └─ analytics_bridge.dart
│  └─ shared/
│     ├─ design_system/
│     ├─ models/
│     └─ utils/
├─ pigeon/
├─ integration_test/
├─ test/
└─ scripts/
```

## Core Architectural Rules

### 1. Native owns app-level concerns

Native iOS and Android apps remain the owners of:

- global `UserSession`
- app root navigation
- tab and stack navigation outside Flutter feature boundaries
- native SDK integration
- analytics sinks
- release / distribution / app lifecycle

### 2. Flutter owns feature-level concerns

Flutter owns:

- feature UI
- feature-local state
- feature-local internal routing
- shared feature presentation logic

For the first feature, Flutter owns the admin list/detail/moderation flow.

### 3. Session is passed to Flutter, but source of truth stays native

iOS and Android both keep a global singleton `UserSession`.

When launching a Flutter feature, the native app creates and passes a `SessionSnapshot`.

Flutter uses the snapshot as read-only context for:

- rendering user-aware UI
- role-aware guards
- telemetry context
- feature initialization

Native remains the source of truth.

If session changes while Flutter is alive, native sends a session update event.

### 4. v1 API execution stays native

In v1, Flutter does not directly call privileged admin endpoints.

Instead:

- Flutter requests admin actions through the host bridge.
- Native validates the active session / role.
- Native injects the current user uuid where required.
- Native calls existing domain / repository logic.
- Native returns typed results back to Flutter.

This keeps the current migration safer while the backend auth boundary remains weak.

## Host Contract v1

### Launch Context

Every Flutter feature is launched with a `HostLaunchContext`.

Suggested shape:

```text
hostContractVersion: Int
featureId: String
featureVersion: String
session: SessionSnapshot
entryPayload: FeatureEntryPayload
featureFlags: Map<String, Bool>
locale: String
environment: String
```

### Session Snapshot

Suggested shape:

```text
userUuid: String
nickname: String?
role: String
isLoggedIn: Bool
provider: String?
locale: String
```

This is a DTO-style snapshot, not a live singleton reference.

### Feature Entry Payload

For `admin.popup_management`, suggested payload:

```text
initialTab: "list"
initialSubmissionId: Int?
initialFilter: "all" | "pending" | "approved" | "rejected"
```

### Native -> Flutter events

Suggested events:

- `sessionUpdated`
- `sessionInvalidated`
- `hostThemeChanged`

### Flutter -> Native events

Suggested events:

- `close`
- `completed`
- `needsRefresh`
- `openNativeRoute`
- `openExternalUrl`
- `logEvent`

## Feature ID Strategy

Feature IDs are stable public identifiers between native hosts and Flutter.

Examples:

- `admin.popup_management`
- `review.management`
- `campaign.editor`
- `profile.creator_tools`

Guidelines:

- keep IDs domain-oriented, not screen-class-oriented
- let one feature ID own an internal flow
- avoid exposing every internal Flutter screen as a top-level host feature unless necessary

For the first migration, use one public feature ID:

- `admin.popup_management`

Inside Flutter, the feature can internally route between list/detail/result states.

## Admin Feature Gateway v1

The first feature uses a native-backed gateway.

Flutter requests:

- `fetchSubmissionList(filter)`
- `fetchSubmissionDetail(submissionId)`
- `approveSubmission(submissionId, payload)`
- `rejectSubmission(submissionId, payload)`

Native host performs:

- session existence check
- role validation
- current user uuid injection
- existing native domain / repository call
- result mapping back to Flutter DTOs

## Why not direct Flutter HTTP in v1?

Current PopPang native code indicates admin access is strongly tied to a user uuid parameter at the application layer.

Until backend auth boundaries are improved, v1 should not expand privileged execution into direct Flutter networking.

So the rule is:

- session context can go to Flutter
- privileged admin execution remains in native

## iOS Integration Strategy

Primary direction:

- consume prebuilt iOS Flutter artifacts
- keep app integration through a generic `FlutterFeatureHost`
- pass `featureId + SessionSnapshot + EntryPayload`

Recommended responsibilities on iOS:

- hold the global `UserSession`
- create `SessionSnapshot`
- launch `FlutterFeatureHost`
- observe `completed` / `close` / `needsRefresh`
- manage cached engine lifecycle

## Android Integration Strategy

Primary direction:

- consume prebuilt Android AAR artifacts
- use the same host contract as iOS
- keep a generic Android `FlutterFeatureHost`

Recommended responsibilities on Android:

- hold the global `UserSession`
- create `SessionSnapshot`
- launch the Flutter host Activity / Fragment
- observe feature events
- manage cached engine lifecycle

## Runtime Strategy

Recommended v1 runtime approach:

- one shared cached engine for Flutter features
- one generic host wrapper on each platform
- feature routing by `featureId`

When more Flutter features are added, review whether `FlutterEngineGroup` style optimization is needed.

## Distribution Strategy

PopPang-Flutter should be versioned and distributed as a reusable artifact set.

Suggested model:

- iOS: prebuilt iOS artifact bundle
- Android: prebuilt AAR
- native apps pin explicit versions
- native apps update only when adopting a new Flutter feature release

Do not rebuild Flutter on every host app build by default.

## Versioning Policy

Suggested metadata:

```text
hostContractVersion
flutterModuleVersion
minimumIosHostVersion
minimumAndroidHostVersion
supportedFeatureIds
```

Compatibility rules:

- major contract changes require host updates
- minor contract changes only add optional fields
- unsupported contract versions must block feature launch safely

## Security Notes

- `SessionSnapshot` is UI/runtime context, not authority by itself.
- Native remains responsible for validating privileged admin actions.
- Raw secrets and privileged host-only internals should not become general-purpose Flutter state.
- Future direct HTTP execution from Flutter should only be considered after backend auth boundaries are improved.

## Recommended Migration Sequence

1. Create this repository and lock Host Contract v1.
2. Implement the generic hosted Flutter entry layer.
3. Implement `admin.popup_management` in Flutter.
4. Build iOS host wrapper and session handoff.
5. Build Android host wrapper and session handoff.
6. Connect the native admin gateway.
7. Verify parity against the current native admin flow.
8. Remove or retire the native admin UI after QA sign-off.

## Success Criteria

The migration is complete when:

- both iOS and Android open the same shared admin feature
- both platforms pass the same session contract
- approve/reject/list/detail behavior matches native expectations
- the host can add future Flutter features without inventing a new bridge model each time

