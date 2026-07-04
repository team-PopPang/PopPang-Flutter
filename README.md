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

## 저장소 구조

권장 목표 구조는 아래와 같습니다.

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

### 3. Session은 Flutter로 전달하되 source of truth는 네이티브에 둔다

iOS와 Android는 각각 전역 singleton `UserSession`을 유지합니다.

Flutter feature를 실행할 때 네이티브 앱은 `SessionSnapshot`을 만들어 Flutter에 전달합니다.

Flutter는 이 snapshot을 아래 용도로 사용합니다.

- 사용자 문맥이 반영된 UI 렌더링
- role 기반 접근 가드
- telemetry context
- feature 초기화

하지만 source of truth는 계속 네이티브입니다.

Flutter가 떠 있는 동안 session이 바뀌면 네이티브가 session update event를 보냅니다.

### 4. v1에서는 권한 있는 관리자 API 실행을 네이티브가 소유한다

v1에서는 Flutter가 관리자 권한이 필요한 endpoint를 직접 호출하지 않습니다.

대신:

- Flutter는 host bridge를 통해 관리자 액션을 요청합니다.
- 네이티브는 현재 세션과 role을 검증합니다.
- 필요한 경우 현재 로그인 사용자 uuid를 주입합니다.
- 기존 네이티브 domain / repository 로직을 호출합니다.
- 결과를 다시 typed DTO로 Flutter에 반환합니다.

이 방식은 현재 백엔드 인증 경계가 약한 상태에서 마이그레이션 리스크를 줄이기 위한 전략입니다.

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

## Admin Feature Gateway v1

첫 번째 feature는 `native-backed gateway`를 사용합니다.

Flutter가 요청하는 동작:

- `fetchSubmissionList(filter)`
- `fetchSubmissionDetail(submissionId)`
- `approveSubmission(submissionId, payload)`
- `rejectSubmission(submissionId, payload)`

네이티브 host가 수행하는 일:

- session 존재 확인
- role 검증
- 현재 사용자 uuid 주입
- 기존 네이티브 domain / repository 호출
- 결과를 Flutter DTO로 매핑

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
2. 공용 hosted Flutter entry 계층을 만든다.
3. `admin.popup_management` feature를 Flutter로 구현한다.
4. iOS host wrapper와 session handoff를 연결한다.
5. Android host wrapper와 session handoff를 연결한다.
6. native admin gateway를 붙인다.
7. 기존 네이티브 관리자 흐름과 parity를 검증한다.
8. QA 완료 후 기존 네이티브 관리자 UI를 제거하거나 retire한다.

## 완료 기준

아래 조건이 만족되면 첫 마이그레이션이 완료된 것입니다.

- iOS와 Android가 같은 관리자 Flutter feature를 연다.
- 두 플랫폼이 같은 session contract를 전달한다.
- 목록 / 상세 / 승인 / 반려 동작이 기존 기대와 일치한다.
- 이후 다른 Flutter feature를 추가할 때 새로운 bridge 모델을 다시 만들 필요가 없다.
