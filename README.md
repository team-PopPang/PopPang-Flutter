# PopPang-Flutter

`PopPang-Flutter`는 PopPang 네이티브 앱(iOS, Android)에서 공통으로 사용할 Flutter feature 저장소입니다.

첫 번째 대상은 팝업 관리자 페이지이며, 현재 iOS/Android에 각각 존재하는 네이티브 관리자 UI를 하나의 Flutter 구현으로 대체하는 것을 목표로 합니다.

이 저장소는 PopPang 전체 앱을 Flutter로 다시 만드는 프로젝트가 아닙니다.  
네이티브 앱이 임베드해서 사용할 수 있는 `공용 Flutter feature 플랫폼`입니다.

## 목표

- 팝업 관리자 페이지를 Flutter로 한 번만 구현하고 iOS/AOS에서 함께 사용한다.
- 앱 세션, 앱 전역 네비게이션, 네이티브 SDK, 배포 책임은 계속 네이티브 앱이 소유한다.
- Flutter를 재사용 가능한 feature 계층으로 두어 이후 다른 기능 view도 같은 방식으로 추가할 수 있게 한다.
- 네이티브 앱이 Flutter feature를 실행하고, 세션을 전달하고, 결과를 받는 방식을 표준화한다.
- 같은 feature 코드를 유지한 채 네이티브 임베드 실행과 Flutter 단독 데모 실행을 모두 지원한다.

## 빠른 시작

처음 이 저장소를 열었을 때는 아래 순서로 시작하는 것을 권장합니다.

### 1. 필수 전제

- Flutter SDK가 설치되어 있어야 한다.
- `main_demo.dart`는 Flutter 단독 데모 실행 진입점이다.
- `main_hosted.dart`는 iOS/AOS host가 임베드할 때 사용하는 진입점이다.

### 2. Flutter 단독 데모 실행

기본 데모 실행:

```bash
flutter pub get
flutter run -t lib/main_demo.dart
```

특정 feature 바로 실행:

```bash
flutter run -t lib/main_demo.dart --dart-define=DEMO_FEATURE=admin.popup_management
```

### 3. 최소 확인 항목

- 데모 홈 또는 feature catalog가 보이는지
- 관리자 preset으로 `admin.popup_management`를 열 수 있는지
- 목록 -> 상세 -> 승인/반려 흐름이 mock 데이터로 동작하는지

### 4. Hosted 연동 전 확인 항목

- `HostLaunchContext`
- `SessionSnapshot`
- `AuthContext`
- `FeatureEntryPayload`
- `Flutter -> Native Event`
- `Native -> Flutter Event`

위 계약이 iOS/AOS에서 같은 의미로 구현되는지 먼저 맞춘 뒤 임베드를 시작한다.

## 현재 결정된 것

- `PopPang-Flutter`는 PopPang 전체 앱이 아니라 공용 Flutter feature 플랫폼이다.
- 첫 번째 feature는 `admin.popup_management`다.
- hosted mode와 demo mode를 동시에 지원한다.
- feature 코드는 hosted/demo에서 동일하게 유지한다.
- Flutter feature는 feature별 클린 아키텍처 레이어를 따른다.
- Flutter feature는 네이티브 usecase를 직접 알지 않는다.
- v1에서도 Flutter feature는 자체 repository를 통해 관리자 API를 직접 호출할 수 있다.
- 관리자 권한 검증의 최종 책임은 서버가 가진다.
- iOS/AOS는 전역 `UserSession`을 source of truth로 유지하고 Flutter에는 `SessionSnapshot`을 전달한다.

## 아직 미정인 것

- iOS artifact를 어떤 배포 포맷과 경로로 최종 고정할지
- Android AAR 배포 저장소와 버전 릴리즈 플로우를 어떻게 자동화할지
- Flutter feature가 늘어났을 때 `FlutterEngineGroup` 전환 시점
- demo mode에서 real dev API 연결을 허용할지 여부
- contract 문서를 README에서 분리해 `docs/` 체계로 가져갈 시점

## 이번 범위에서 하지 않는 일

- PopPang 전체 앱을 Flutter로 전환하지 않는다.
- 앱 루트 네비게이션 ownership을 네이티브에서 Flutter로 옮기지 않는다.
- 첫 번째 마이그레이션에서 백엔드 인증 체계나 API 계약을 전면 개편하지 않는다.
- 모든 PopPang 기능을 한 번에 Flutter로 이전하지 않는다.

## 첫 번째 Flutter Feature

첫 번째 Flutter feature는 아래 하나입니다.

- `admin.popup_management`

이 feature는 아래 흐름을 포함합니다.

- 팝업 제보 목록
- 필터 상태
- 팝업 제보 상세
- 승인 / 반려 액션
- 처리 완료 후 목록 갱신

네이티브 앱 입장에서는 이것이 `하나의 feature entry`입니다.

Flutter 내부에서는 이 feature가 여러 화면과 내부 라우팅 흐름을 가질 수 있습니다.

## 플랫폼 모델

`PopPang-Flutter`는 네이티브 앱이 공통 host contract를 통해 소비합니다.

개념적으로는 아래와 같습니다.

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

즉:

- Flutter는 앱 안의 하나의 `feature platform`입니다.
- 앱 전역 네비게이션과 세션은 계속 네이티브가 소유합니다.
- Flutter는 feature 단위 UI와 내부 흐름을 소유합니다.

## 실행 모드

`PopPang-Flutter`는 아래 두 실행 모드를 동시에 지원하는 것을 기본 방향으로 합니다.

### 1. Hosted Mode

네이티브 앱(iOS / Android)이 Flutter feature를 임베드해서 실행하는 모드입니다.

특징:

- 네이티브가 `featureId + SessionSnapshot + AuthContext + EntryPayload`를 전달합니다.
- 앱 세션 source of truth는 네이티브가 소유합니다.
- 앱 전역 네비게이션은 네이티브가 소유합니다.
- Flutter repository는 전달받은 인증 문맥으로 관리자 API를 직접 호출할 수 있습니다.
- 네이티브 bridge는 세션 전달, 종료, 외부 링크, 네이티브 전용 capability 연결에 사용합니다.

### 2. Demo Mode

Flutter만 단독 실행해서 feature 데모와 QA 확인을 할 수 있는 모드입니다.

특징:

- Flutter 내부에서 demo용 session preset을 선택할 수 있습니다.
- feature catalog에서 원하는 Flutter feature를 직접 열 수 있습니다.
- 기본적으로 mock / demo gateway를 사용합니다.
- 네이티브 앱 없이도 UI, 상태, 내부 흐름을 빠르게 확인할 수 있습니다.

핵심 원칙:

- `feature 코드는 하나`
- `실행 모드만 둘`
- `hosted / demo 모두 같은 contract 사용`

## 저장소 구조

권장 목표 구조는 아래와 같습니다.

```text
PopPang-Flutter
├─ lib/
│  ├─ main_hosted.dart
│  ├─ main_demo.dart
│  ├─ app/
│  │  ├─ hosted_entry/
│  │  ├─ bootstrap/
│  │  └─ demo/
│  ├─ contract/
│  │  ├─ host_contract.dart
│  │  ├─ session_snapshot.dart
│  │  ├─ feature_entry_payload.dart
│  │  └─ flutter_feature_event.dart
│  ├─ features/
│  │  ├─ admin_popup_management/
│  │  │  ├─ presentation/
│  │  │  ├─ domain/
│  │  │  ├─ usecase/
│  │  │  ├─ repository/
│  │  │  └─ infrastructure/
│  │  └─ ...
│  ├─ host_bridge/
│  │  ├─ hosted/
│  │  └─ demo/
│  └─ shared/
│     ├─ design_system/
│     ├─ models/
│     └─ utils/
├─ pigeon/
├─ integration_test/
├─ test/
└─ scripts/
```

각 Flutter feature는 독립적인 클린 아키텍처 레이어를 가지는 것을 기본 원칙으로 합니다.

예시:

```text
features/admin_popup_management/
├─ presentation/
│  ├─ pages/
│  ├─ widgets/
│  ├─ state/
│  └─ controllers/
├─ domain/
│  ├─ entities/
│  └─ value_objects/
├─ usecase/
│  ├─ get_submission_list.dart
│  ├─ get_submission_detail.dart
│  ├─ approve_submission.dart
│  └─ reject_submission.dart
├─ repository/
│  └─ admin_popup_management_repository.dart
└─ infrastructure/
   ├─ hosted/
   │  └─ hosted_admin_popup_management_repository.dart
   └─ demo/
      └─ demo_admin_popup_management_repository.dart
```

## 핵심 아키텍처 원칙

### 1. 앱 레벨 책임은 네이티브가 소유한다

iOS / Android 네이티브 앱은 계속 아래를 소유합니다.

- 전역 `UserSession`
- 앱 루트 네비게이션
- Flutter feature 바깥의 탭 / 스택 네비게이션
- 네이티브 SDK 연동
- analytics sink
- 배포 / 앱 수명주기 / 릴리즈 orchestration

### 2. feature 레벨 책임은 Flutter가 소유한다

Flutter는 아래를 소유합니다.

- feature UI
- feature 내부 상태
- feature 내부 라우팅
- 공용 feature 프레젠테이션 로직

첫 번째 feature 기준으로는 관리자 목록 / 상세 / 승인 / 반려 흐름을 Flutter가 소유합니다.

### 3. 각 Flutter feature는 클린 아키텍처 레이어를 따른다

각 feature는 가능한 한 아래 의존 방향을 유지합니다.

```text
presentation -> usecase -> repository(protocol)
```

세부 원칙:

- `presentation`은 UI, 상태, 사용자 액션 처리에 집중한다.
- `domain`은 feature의 entity / value object를 가진다.
- `usecase`는 feature 동작 단위를 표현한다.
- `repository`는 feature가 의존하는 추상 계약만 가진다.
- `infrastructure`는 실제 구현을 제공한다.

이 구조의 핵심은 아래와 같습니다.

- Flutter feature는 네이티브 `Usecase`를 직접 알지 않는다.
- Flutter feature는 네이티브 `Repository` 타입을 직접 import하지 않는다.
- Flutter feature는 오직 자기 feature의 `repository protocol`만 바라본다.

즉 네이티브와 Flutter의 경계는 `infrastructure` 구현체에서만 만납니다.

### 4. Session은 Flutter로 전달하되 source of truth는 네이티브에 둔다

iOS와 Android는 각각 전역 singleton `UserSession`을 유지합니다.

Flutter feature를 실행할 때 네이티브 앱은 `SessionSnapshot`을 만들어 Flutter에 전달합니다.

Flutter는 이 snapshot을 아래 용도로 사용합니다.

- 사용자 문맥이 반영된 UI 렌더링
- role 기반 접근 가드
- telemetry context
- feature 초기화

하지만 source of truth는 계속 네이티브입니다.

Flutter가 떠 있는 동안 session이 바뀌면 네이티브가 session update event를 보냅니다.

### 5. v1에서도 관리자 API 호출은 Flutter repository가 직접 수행할 수 있다

v1에서는 Flutter feature가 자기 repository 구현을 통해 관리자 endpoint를 직접 호출할 수 있습니다.

대신:

- Flutter `usecase`는 feature의 `repository protocol`을 호출합니다.
- hosted mode에서는 repository 구현체가 `AuthContext`와 환경값을 사용해 서버 API를 직접 호출합니다.
- 네이티브는 현재 `UserSession`을 기준으로 `SessionSnapshot`과 인증 문맥을 Flutter에 전달합니다.
- 서버는 전달된 인증 토큰과 role을 기준으로 최종 관리자 권한을 검증합니다.
- 네이티브 bridge는 HTTP 우회 호출 계층이 아니라 세션 전달, 종료, 네이티브 전용 기능 연결에 집중합니다.

이 방식은 아래 요구와 가장 잘 맞습니다.

- Flutter feature가 독립적으로 실행되어야 한다.
- demo mode에서도 같은 feature 구조를 유지해야 한다.
- 각 feature가 자체 `presentation / domain / usecase / repository` 레이어를 가져야 한다.
- Flutter feature가 네이티브 usecase를 모른 채 동작해야 한다.

### 6. Feature는 하나로 유지하고 실행 환경만 분리한다

`admin.popup_management` feature 코드는 hosted mode와 demo mode에서 동일해야 합니다.

달라지는 것은 아래 두 가지뿐입니다.

- session 공급 방식
- gateway / bridge 구현체

즉:

- hosted mode: native session + auth context + API repository
- demo mode: demo session preset + demo/mock repository

feature 자체는 실행 모드에 따라 갈라지지 않습니다.

### 7. 실행 모드별로 바뀌는 것은 repository 구현체다

같은 feature라도 실행 모드에 따라 concrete repository 구현은 달라질 수 있습니다.

- hosted mode: host가 전달한 인증 문맥으로 실제 API를 직접 호출하는 repository 구현체 사용
- demo mode: mock / preset 데이터를 제공하는 repository 구현체 또는 선택적 dev API 구현체 사용

하지만 아래는 동일해야 합니다.

- presentation 구조
- domain entity
- usecase 시그니처
- repository protocol
- feature 내부 라우팅

## Host Contract v1

### Launch Context

모든 Flutter feature는 `HostLaunchContext`로 실행됩니다.

권장 형태:

```text
hostContractVersion: Int
featureId: String
featureVersion: String
session: SessionSnapshot
authContext: AuthContext?
entryPayload: FeatureEntryPayload
featureFlags: Map<String, Bool>
locale: String
environment: String
```

### Session Snapshot

권장 형태:

```text
userUuid: String
nickname: String?
role: String
isLoggedIn: Bool
provider: String?
locale: String
```

이 값은 live singleton 참조가 아니라 DTO 형태의 snapshot입니다.

### Auth Context

권장 형태:

```text
accessToken: String?
tokenType: String?
apiBaseUrl: String
```

`SessionSnapshot`은 사용자 문맥을 표현하고, 실제 HTTP 인증과 API 호출에 필요한 값은 `AuthContext`가 담당합니다.

장기적으로는 `userUuid`만으로 관리자 권한을 판단하지 않고, 인증 토큰과 서버 검증을 기준으로 동작하는 것을 목표로 합니다.

### Feature Entry Payload

`admin.popup_management`에 대한 권장 payload:

```text
initialTab: "list"
initialSubmissionId: Int?
initialFilter: "all" | "pending" | "approved" | "rejected"
```

### Native -> Flutter 이벤트

권장 이벤트:

- `sessionUpdated`
- `sessionInvalidated`
- `hostThemeChanged`

### Flutter -> Native 이벤트

권장 이벤트:

- `close`
- `completed`
- `needsRefresh`
- `openNativeRoute`
- `openExternalUrl`
- `logEvent`

## Host Contract 상세 표

### Launch Context

| 필드 | 타입 | 필수 여부 | 생성 주체 | 설명 |
| --- | --- | --- | --- | --- |
| `hostContractVersion` | `Int` | 필수 | Native host | host/Flutter 사이 계약 버전 |
| `featureId` | `String` | 필수 | Native host 또는 Demo launcher | 실행할 Flutter feature 식별자 |
| `featureVersion` | `String` | 권장 | Native host 또는 Demo launcher | 현재 feature 배포 버전 또는 디버그 버전 |
| `session` | `SessionSnapshot` | 필수 | Native host 또는 Demo launcher | 실행 시점 세션 문맥 |
| `authContext` | `AuthContext?` | 권장 | Native host 또는 Demo launcher | 직접 API 호출에 필요한 인증 및 환경 문맥 |
| `entryPayload` | `FeatureEntryPayload` | 선택 | Native host 또는 Demo launcher | feature 초기 진입 파라미터 |
| `featureFlags` | `Map<String, Bool>` | 선택 | Native host 또는 Demo launcher | 실험/분기용 feature flag |
| `locale` | `String` | 필수 | Native host 또는 Demo launcher | 언어/지역 설정 |
| `environment` | `String` | 필수 | Native host 또는 Demo launcher | `prod`, `stage`, `demo` 같은 실행 환경 |

### Session Snapshot

| 필드 | 타입 | 필수 여부 | 설명 |
| --- | --- | --- | --- |
| `userUuid` | `String` | 로그인 시 필수 | 현재 사용자 식별자 |
| `nickname` | `String?` | 선택 | UI 표시용 닉네임 |
| `role` | `String` | 필수 | 예: `admin`, `user` |
| `isLoggedIn` | `Bool` | 필수 | 로그인 여부 |
| `provider` | `String?` | 선택 | 예: `kakao`, `google`, `apple` |
| `locale` | `String` | 필수 | 세션 기준 로케일 |

### Auth Context

| 필드 | 타입 | 필수 여부 | 설명 |
| --- | --- | --- | --- |
| `accessToken` | `String?` | hosted에서는 권장 | 서버 인증 헤더 구성에 사용하는 토큰 |
| `tokenType` | `String?` | 선택 | 예: `Bearer` |
| `apiBaseUrl` | `String` | 필수 | feature가 호출할 API base URL |

### Feature Entry Payload

| 필드 | 타입 | 필수 여부 | 설명 |
| --- | --- | --- | --- |
| `initialTab` | `String` | 선택 | feature 시작 탭 또는 시작 섹션 |
| `initialSubmissionId` | `Int?` | 선택 | 특정 상세로 바로 진입할 때 사용 |
| `initialFilter` | `String` | 선택 | 초기 목록 필터 |

### Native -> Flutter 이벤트

| 이벤트 | 필수 여부 | 설명 |
| --- | --- | --- |
| `sessionUpdated` | 권장 | 세션이 바뀌었을 때 최신 snapshot 전달 |
| `sessionInvalidated` | 권장 | 로그아웃 또는 권한 상실 시 전달 |
| `hostThemeChanged` | 선택 | 테마/스타일 변경 시 전달 |

### Flutter -> Native 이벤트

| 이벤트 | 필수 여부 | 설명 |
| --- | --- | --- |
| `close` | 필수 | feature 종료 요청 |
| `completed` | 권장 | 중요한 작업 완료 후 결과 전달 |
| `needsRefresh` | 권장 | 네이티브 host가 외부 목록/상태를 새로고침해야 할 때 |
| `openNativeRoute` | 선택 | 앱 바깥 또는 네이티브 화면으로 이동 요청 |
| `openExternalUrl` | 선택 | 외부 링크 실행 요청 |
| `logEvent` | 선택 | analytics 이벤트 전달 |

## Feature ID 전략

`featureId`는 네이티브 host와 Flutter 사이에서 사용하는 안정적인 공개 식별자입니다.

예시:

- `admin.popup_management`
- `review.management`
- `campaign.editor`
- `profile.creator_tools`

가이드라인:

- 화면 클래스명이 아니라 도메인 의미 중심으로 짓는다.
- 하나의 `featureId`가 하나의 내부 flow를 소유하게 한다.
- 필요하지 않다면 Flutter 내부의 모든 화면을 top-level host feature로 외부 공개하지 않는다.

첫 번째 마이그레이션에서는 아래 공개 feature ID 하나를 사용합니다.

- `admin.popup_management`

목록 / 상세 / 결과 상태 전환은 Flutter 내부에서 처리합니다.

## Feature Registry 전략

`featureId` 기반 분기는 필요하지만, 하나의 거대한 `switch`로 모든 feature를 처리하는 구조는 지양합니다.

대신 공용 `FeatureRegistry`를 두고 아래처럼 관리합니다.

- `admin.popup_management -> AdminPopupManagementFeature`
- `review.management -> ReviewManagementFeature`
- `campaign.editor -> CampaignEditorFeature`

즉:

- artifact / runtime은 하나
- feature 매핑은 registry에서 관리
- 실제 구현은 feature 모듈 단위로 분리

이 구조를 사용하면 새로운 Flutter feature가 추가돼도 host contract는 유지한 채 registry에 연결만 추가하면 됩니다.

## 새 Feature 추가 템플릿

새 Flutter feature를 추가할 때는 아래 구조를 기본 템플릿으로 사용합니다.

```text
features/<feature_name>/
├─ presentation/
│  ├─ pages/
│  ├─ widgets/
│  ├─ state/
│  └─ controllers/
├─ domain/
│  ├─ entities/
│  └─ value_objects/
├─ usecase/
├─ repository/
│  └─ <feature_name>_repository.dart
└─ infrastructure/
   ├─ hosted/
   └─ demo/
```

### 새 feature 추가 체크리스트

- `featureId`를 먼저 정한다.
- `domain` entity와 value object를 정의한다.
- `usecase`를 사용자 액션 단위로 쪼갠다.
- `repository protocol`을 feature 내부에서 정의한다.
- hosted/demo용 concrete repository 구현체를 각각 만든다.
- `FeatureRegistry`에 feature를 등록한다.
- demo catalog에서 열 수 있게 연결한다.
- 최소 widget test와 demo smoke flow를 추가한다.

### 네이밍 가이드

- featureId: 도메인 의미 중심으로 짓는다.
- repository protocol: `<FeatureName>Repository`
- usecase: 동사 기준으로 `GetX`, `UpdateX`, `ApproveX`
- demo 구현체: `Demo<FeatureName>Repository`
- hosted 구현체: `Hosted<FeatureName>Repository`

## Admin Feature Repository v1

첫 번째 feature는 `API-backed repository implementation`을 사용합니다.

Flutter feature 내부에서는 아래 usecase를 가질 수 있습니다.

- `GetSubmissionList`
- `GetSubmissionDetail`
- `ApproveSubmission`
- `RejectSubmission`

이 usecase들은 아래 repository protocol만 의존합니다.

- `AdminPopupManagementRepository`

hosted mode에서 concrete repository는 내부적으로 아래 동작을 수행합니다.

- `fetchSubmissionList(filter)`
- `fetchSubmissionDetail(submissionId)`
- `approveSubmission(submissionId, payload)`
- `rejectSubmission(submissionId, payload)`

그리고 이 구현은 아래 원칙을 따릅니다.

- Flutter feature 내부에서 직접 HTTP 호출을 수행한다.
- 네이티브 host는 세션 스냅샷과 인증 문맥을 전달한다.
- 서버가 access token / role / 기타 인증 정보로 최종 권한을 검증한다.
- 네이티브 bridge는 API 우회 계층이 아니라 앱 통합 계층으로 유지한다.

## Demo 모드 전략

### 목표

Demo mode는 디자이너, QA, 기획자, 개발자가 네이티브 앱 없이도 Flutter feature를 단독 실행해 UI와 흐름을 빠르게 확인할 수 있도록 하기 위한 모드입니다.

### 기본 원칙

- demo mode도 hosted mode와 같은 `featureId`, `SessionSnapshot`, `EntryPayload` 구조를 사용한다.
- feature 코드는 hosted / demo에서 동일해야 한다.
- usecase와 repository protocol도 hosted / demo에서 동일해야 한다.
- v1에서는 real privileged API 대신 mock / demo repository 구현을 기본으로 사용한다.

### Demo Session Preset

demo mode에서는 아래와 같은 preset을 제공하는 것이 좋습니다.

- 관리자 계정 preset
- 일반 사용자 preset
- 로그아웃 preset

각 preset은 실제 네이티브와 동일한 `SessionSnapshot` 형태를 사용합니다.

### Demo Gateway

demo mode의 기본 repository 구현체는 mock 데이터 기반으로 동작합니다.

예:

- 목록 mock 데이터
- 상세 mock 데이터
- 승인 / 반려 성공 결과 mock
- 처리 후 refresh mock

이렇게 해야:

- feature 흐름을 빠르게 확인할 수 있고
- demo 실행이 실제 관리자 권한 경계를 직접 건드리지 않으며
- hosted mode와 feature parity를 유지하기 쉽습니다.

### Demo 앱 UX

단독 실행 시 첫 화면은 `Demo Home` 또는 `Feature Catalog`를 권장합니다.

권장 구성:

- `Demo Mode` 배지
- session preset 선택
- feature 목록
- feature direct launch
- entry payload 편집
- event / log panel

예시 흐름:

1. 관리자 preset 선택
2. `admin.popup_management` 선택
3. 초기 필터 `pending` 선택
4. 관리자 목록 화면 진입

### 실행 방식

Flutter 단독 실행:

```bash
flutter run -t lib/main_demo.dart
```

특정 feature 바로 실행:

```bash
flutter run -t lib/main_demo.dart --dart-define=DEMO_FEATURE=admin.popup_management
```

네이티브 임베드 실행:

- iOS / Android host는 `main_hosted.dart`를 진입점으로 사용
- `featureId + SessionSnapshot + EntryPayload` 전달

## Hosted Mode vs Demo Mode 비교

| 항목 | Hosted Mode | Demo Mode |
| --- | --- | --- |
| 실행 주체 | iOS / Android host | Flutter 단독 실행 |
| 진입점 | `main_hosted.dart` | `main_demo.dart` |
| 세션 source of truth | Native `UserSession` singleton | Demo preset |
| 세션 전달 방식 | `SessionSnapshot` | `SessionSnapshot` |
| feature 코드 | 공통 | 공통 |
| usecase | 공통 | 공통 |
| repository protocol | 공통 | 공통 |
| repository 구현체 | 직접 API 호출형 | Mock / preset 데이터형 또는 선택적 dev API형 |
| 권한 있는 관리자 API 실행 | Flutter repository가 직접 호출, 서버가 최종 검증 | 기본적으로 mock, 필요 시 dev API |
| 주 용도 | 실제 앱 임베드 | UI/흐름 데모, QA, 설계 확인 |
| 성공 기준 | native와 기능 parity | hosted와 기능 parity |

## 왜 Flutter repository direct API 호출을 기본으로 하는가

현재 `PopPang-Flutter`는 단순 임베드 뷰가 아니라 독립적인 Flutter feature 플랫폼을 목표로 합니다.

따라서 아래 조건을 만족하려면 Flutter feature가 자체 repository를 통해 API를 직접 호출하는 구조가 더 자연스럽습니다.

- Flutter 단독 demo 실행이 가능해야 한다.
- hosted/demo가 같은 feature 구조를 공유해야 한다.
- 각 feature가 자체 `usecase`와 `repository`를 가져야 한다.
- Flutter feature가 네이티브 usecase를 몰라도 되어야 한다.

다만 이 구조의 전제는 아래와 같습니다.

- `SessionSnapshot`만으로 권한을 판단하지 않는다.
- 실제 권한 검증은 서버가 수행한다.
- 네이티브는 Flutter에 인증 문맥을 전달하되, 앱 전역 세션 source of truth는 계속 소유한다.

## iOS 연동 전략

기본 방향:

- 사전 생성된 iOS Flutter artifact를 소비한다.
- 앱 통합은 공용 `FlutterFeatureHost`를 통해 수행한다.
- `featureId + SessionSnapshot + AuthContext + EntryPayload`를 전달한다.

iOS host의 권장 책임:

- 전역 `UserSession` 유지
- `SessionSnapshot` 생성
- `AuthContext` 생성
- `FlutterFeatureHost` 실행
- `completed` / `close` / `needsRefresh` 이벤트 처리
- cached engine lifecycle 관리

## Android 연동 전략

기본 방향:

- 사전 빌드된 Android AAR artifact를 소비한다.
- iOS와 동일한 host contract를 사용한다.
- Android 쪽에도 공용 `FlutterFeatureHost`를 둔다.

Android host의 권장 책임:

- 전역 `UserSession` 유지
- `SessionSnapshot` 생성
- `AuthContext` 생성
- Flutter host Activity / Fragment 실행
- feature event 처리
- cached engine lifecycle 관리

## 런타임 전략

v1 권장 런타임 전략:

- Flutter feature들을 위한 shared cached engine 1개
- 플랫폼별 공용 host wrapper 1개
- 실제 feature 분기는 `featureId` 기반으로 처리
- Flutter 단독 데모 실행은 `main_demo.dart` 진입점으로 처리
- hosted / demo 모두 같은 feature registry를 사용
- hosted / demo 모두 같은 usecase / repository protocol을 사용
- 실행 모드에 따라 concrete repository 구현만 교체

Flutter feature가 늘어나면 `FlutterEngineGroup` 계열 최적화가 필요한지 후속 검토합니다.

## 배포 전략

`PopPang-Flutter`는 재사용 가능한 artifact 세트로 버전 관리하고 배포합니다.

권장 모델:

- iOS: prebuilt iOS artifact bundle
- Android: prebuilt AAR
- 네이티브 앱은 명시적인 버전을 pinning해서 사용
- 네이티브 앱은 새로운 Flutter feature release를 도입할 때만 버전을 올림

기본적으로 host app 빌드 때마다 Flutter를 매번 다시 생성하지 않습니다.

## 배포 체크리스트

릴리즈 전 최소 확인 항목:

- `hostContractVersion` 변경 여부 확인
- iOS artifact와 Android artifact가 같은 feature 기준으로 생성됐는지 확인
- `admin.popup_management` demo smoke flow 확인
- hosted/demo에서 동일한 `featureId`와 payload로 진입 가능한지 확인
- breaking change가 있으면 host 최소 버전 갱신 여부 확인
- README와 실제 계약이 어긋나지 않는지 확인

## 버전 정책

권장 메타데이터:

```text
hostContractVersion
flutterModuleVersion
minimumIosHostVersion
minimumAndroidHostVersion
supportedFeatureIds
```

호환성 규칙:

- contract major 변경은 host 업데이트가 필요하다.
- contract minor 변경은 optional field 추가만 허용한다.
- 지원하지 않는 contract version이면 feature launch를 안전하게 차단한다.

## 보안 메모

- `SessionSnapshot`은 UI / runtime context이지 authority 그 자체가 아니다.
- 관리자 권한의 최종 검증 책임은 서버에 있다.
- `AuthContext`는 런타임 문맥으로 전달하되, 불필요하게 장기 저장하지 않는다.
- raw secret이나 host-only privileged internal 값을 Flutter 공용 상태로 만들지 않는다.
- 네이티브는 세션 source of truth와 앱 통합 책임을 유지한다.

## 권장 마이그레이션 순서

1. 이 저장소를 만들고 Host Contract v1을 고정한다.
2. `main_hosted.dart`와 `main_demo.dart` 두 실행 진입점을 만든다.
3. 공용 bootstrap / feature registry를 만든다.
4. `admin.popup_management` feature를 Flutter로 구현한다.
5. demo session preset과 demo gateway를 붙인다.
6. iOS host wrapper와 session handoff를 연결한다.
7. Android host wrapper와 session handoff를 연결한다.
8. hosted mode용 API repository 구현을 붙인다.
9. 기존 네이티브 관리자 흐름과 parity를 검증한다.
10. QA 완료 후 기존 네이티브 관리자 UI를 제거하거나 retire한다.

## 완료 기준

아래 조건이 만족되면 첫 마이그레이션이 완료된 것입니다.

- iOS와 Android가 같은 관리자 Flutter feature를 연다.
- 두 플랫폼이 같은 session contract를 전달한다.
- 목록 / 상세 / 승인 / 반려 동작이 기존 기대와 일치한다.
- 이후 다른 Flutter feature를 추가할 때 새로운 bridge 모델을 다시 만들 필요가 없다.
- Flutter 단독 실행으로도 같은 feature를 확인할 수 있다.

## FAQ

### Q. Flutter가 네이티브 Usecase를 직접 호출하나요?

아니요. Flutter feature는 네이티브 usecase를 모릅니다.  
Flutter는 자기 feature의 `repository protocol`만 알고, hosted mode에서는 그 구현체가 전달받은 인증 문맥으로 서버 API를 직접 호출합니다.

### Q. demo mode와 hosted mode는 별도 feature인가요?

아니요. feature는 하나이고, 실행 모드만 다릅니다.  
같은 feature 코드와 같은 usecase / repository protocol을 쓰고, concrete repository 구현만 바뀝니다.

### Q. Flutter가 관리자 API를 직접 호출하나요?

네. 사용자가 원하는 최종 구조 기준으로는 Flutter feature의 repository가 관리자 API를 직접 호출합니다.  
다만 권한 검증은 Flutter가 아니라 서버가 최종적으로 수행해야 합니다.

### Q. 새로운 Flutter feature를 추가할 때 가장 먼저 해야 할 일은 무엇인가요?

`featureId`를 정하고, 그 feature의 `domain`, `usecase`, `repository protocol`을 먼저 정의하는 것이 좋습니다.
