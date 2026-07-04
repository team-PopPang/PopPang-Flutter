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

- 네이티브가 `featureId + SessionSnapshot + EntryPayload`를 전달합니다.
- 앱 세션 source of truth는 네이티브가 소유합니다.
- 앱 전역 네비게이션은 네이티브가 소유합니다.
- 권한 있는 관리자 API 실행은 네이티브 gateway가 담당합니다.

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

### 5. v1에서는 권한 있는 관리자 API 실행을 네이티브가 소유한다

v1에서는 Flutter가 관리자 권한이 필요한 endpoint를 직접 호출하지 않습니다.

대신:

- Flutter `usecase`는 feature의 `repository protocol`을 호출합니다.
- hosted mode에서는 repository 구현체가 host bridge를 통해 관리자 액션을 요청합니다.
- 네이티브는 현재 세션과 role을 검증합니다.
- 필요한 경우 현재 로그인 사용자 uuid를 주입합니다.
- 기존 네이티브 domain / repository 로직을 호출합니다.
- 결과를 다시 typed DTO로 Flutter에 반환합니다.

이 방식은 현재 백엔드 인증 경계가 약한 상태에서 마이그레이션 리스크를 줄이기 위한 전략입니다.

### 6. Feature는 하나로 유지하고 실행 환경만 분리한다

`admin.popup_management` feature 코드는 hosted mode와 demo mode에서 동일해야 합니다.

달라지는 것은 아래 두 가지뿐입니다.

- session 공급 방식
- gateway / bridge 구현체

즉:

- hosted mode: native session + native gateway
- demo mode: demo session preset + demo gateway

feature 자체는 실행 모드에 따라 갈라지지 않습니다.

### 7. 실행 모드별로 바뀌는 것은 repository 구현체다

같은 feature라도 실행 모드에 따라 concrete repository 구현은 달라질 수 있습니다.

- hosted mode: native bridge를 호출하는 repository 구현체 사용
- demo mode: mock / preset 데이터를 제공하는 repository 구현체 사용

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

## Admin Feature Gateway v1

첫 번째 feature는 `native-backed repository implementation`을 사용합니다.

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

그리고 네이티브 host는 아래를 수행합니다.

- session 존재 확인
- role 검증
- 현재 사용자 uuid 주입
- 기존 네이티브 domain / repository 호출
- 결과를 Flutter DTO로 매핑

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
- 현재 약한 관리자 권한 경계를 demo mode가 직접 확장하지 않으며
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

## 왜 v1에서 Flutter direct HTTP를 쓰지 않는가

현재 PopPang 네이티브 코드상 관리자 접근은 앱 레벨에서 사용자 uuid 파라미터에 강하게 의존하고 있습니다.

백엔드 인증 경계가 더 명확해지기 전까지는, 권한 있는 관리자 실행을 Flutter direct networking으로 확장하지 않는 편이 안전합니다.

따라서 v1 원칙은 아래와 같습니다.

- session context는 Flutter로 전달할 수 있다.
- 관리자 권한이 필요한 실행은 네이티브가 소유한다.

## iOS 연동 전략

기본 방향:

- 사전 생성된 iOS Flutter artifact를 소비한다.
- 앱 통합은 공용 `FlutterFeatureHost`를 통해 수행한다.
- `featureId + SessionSnapshot + EntryPayload`를 전달한다.

iOS host의 권장 책임:

- 전역 `UserSession` 유지
- `SessionSnapshot` 생성
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
- 권한 있는 관리자 액션 검증 책임은 계속 네이티브에 있다.
- raw secret이나 host-only privileged internal 값을 Flutter 공용 상태로 만들지 않는다.
- Flutter direct HTTP 실행은 백엔드 인증 경계가 명확해진 뒤에만 재검토한다.

## 권장 마이그레이션 순서

1. 이 저장소를 만들고 Host Contract v1을 고정한다.
2. `main_hosted.dart`와 `main_demo.dart` 두 실행 진입점을 만든다.
3. 공용 bootstrap / feature registry를 만든다.
4. `admin.popup_management` feature를 Flutter로 구현한다.
5. demo session preset과 demo gateway를 붙인다.
6. iOS host wrapper와 session handoff를 연결한다.
7. Android host wrapper와 session handoff를 연결한다.
8. native admin gateway를 붙인다.
9. 기존 네이티브 관리자 흐름과 parity를 검증한다.
10. QA 완료 후 기존 네이티브 관리자 UI를 제거하거나 retire한다.

## 완료 기준

아래 조건이 만족되면 첫 마이그레이션이 완료된 것입니다.

- iOS와 Android가 같은 관리자 Flutter feature를 연다.
- 두 플랫폼이 같은 session contract를 전달한다.
- 목록 / 상세 / 승인 / 반려 동작이 기존 기대와 일치한다.
- 이후 다른 Flutter feature를 추가할 때 새로운 bridge 모델을 다시 만들 필요가 없다.
- Flutter 단독 실행으로도 같은 feature를 확인할 수 있다.
