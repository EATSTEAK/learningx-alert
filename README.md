# LearningX Alert

## 프로젝트명

LearningX Alert

## 프로그램 개요

LearningX Alert는 숭실대학교 SSU LearningX/Canvas의 과제, 퀴즈,
토론, 페이지 등 학습 일정의 마감 정보를 가져와 앱에서 확인하고
로컬 알림을 예약하는 Flutter 앱입니다.

사용자는 앱에서 SSU Canvas 로그인을 진행하고, Canvas access token을
생성 및 저장한 뒤 앞으로 60일 이내의 마감 일정을 동기화할 수 있습니다.
동기화된 일정은 기기 로컬 캐시에 저장되며, 설정한 알림 시점에 맞춰
마감 알림을 받을 수 있습니다.

## 주요 기능 설명

- SSU Canvas WebView 로그인
- Canvas access token 자동 생성 및 안전 저장
- Canvas Planner API 기반 학습 일정 조회
- 과제, 퀴즈, 토론, 위키 페이지 마감 일정 필터링
- 완료된 항목 제외 및 마감일 기준 정렬
- 홈 화면에서 마감 일정 목록과 마지막 동기화 시각 표시
- 새로고침 및 앱 재개 시 일정 재동기화
- 학습 일정 로컬 캐시 저장
- 마감 24시간 전, 1시간 전 로컬 알림 예약
- 알림 시점 설정 및 알림 재예약
- 로그아웃 시 토큰, 캐시, 예약 알림 정리

## 프로젝트 구조

이 저장소는 Dart workspace와 Melos를 사용하는 모노레포입니다.

```text
.
├── apps/
│   └── learningx_alert/      # Flutter 앱
├── packages/
│   └── learningx_api/        # Canvas/LearningX API 클라이언트
├── pubspec.yaml              # Workspace 및 Melos 설정
└── pubspec.lock
```

주요 패키지:

- `apps/learningx_alert`: 로그인, 일정 목록 표시, 설정, 로컬 알림 예약을
  담당하는 Flutter 앱입니다.
- `packages/learningx_api`: Canvas API access token을 사용해 사용자 정보와
  planner item을 가져오고 앱에서 사용하는 `LearningItem` 모델로 변환합니다.

## 본인이 구현한 부분

- 프로젝트 구조 작성 및 Melos 셋업
- Dart workspace 기반 모노레포 구조 구성
- `apps/learningx_alert` 앱 패키지와 `packages/learningx_api` API 패키지
  분리
- Melos를 이용한 분석, 테스트, 코드 생성, 앱 실행 스크립트 작성
- `learningx_api` 패키지 구현
- Canvas/LearningX API 호출을 담당하는 `LearningXApiClient` 작성
- Canvas access token 기반 인증 헤더 구성
- 사용자 정보와 planner item 조회 API 구현
- 페이지네이션된 Canvas API 응답 처리 로직 구현
- API 응답을 앱에서 사용할 `LearningItem` 모델로 변환하는 로직 구현
- 과제, 퀴즈, 토론, 위키 페이지 등 알림 대상 학습 항목 필터링 구현
- 실제 API 확인용 live test 작성
- `LEARNINGX_ACCESS_TOKEN` 환경 변수를 사용해 실제 SSU Canvas API에서
  일정 데이터를 조회하는 테스트 작성
- 조회 기간, 출력 개수, Canvas base URL을 환경 변수로 조절할 수 있도록
  구성
- WebView를 이용한 Canvas token 생성 자동화 구현
- SSU Canvas 로그인 페이지를 WebView로 열고 로그인 세션을 확인하는 흐름
  구현
- 로그인 완료 후 Canvas 설정 페이지로 이동해 access token 생성을 자동화하는
  JavaScript 주입 로직 작성
- 생성된 token을 Flutter 앱으로 전달하고 안전 저장소에 저장하는 bridge 처리
  구현
- token 생성 상태, 실패 메시지, 재시도 흐름을 사용자에게 보여주는 로그인
  화면 구현

## AI 활용 여부 및 활용 범위

AI를 활용했습니다.

활용 범위:

- Flutter/Dart 코드 구조 설계 보조
- Canvas API 연동 방식 검토 보조
- WebView 기반 로그인 및 token 생성 자동화 로직 작성 보조
- Riverpod provider, 로컬 저장소, 알림 예약 코드 작성 보조
- 테스트 코드와 live test 작성 보조
- README 등 문서 작성 보조

최종 코드 검토, 실행 여부 판단, 프로젝트 요구사항 반영은 개발자가 직접 수행했습니다.

## 클론 및 원본 URL

이 프로젝트의 원격 저장소 URL은 다음과 같습니다.

```text
https://github.com/eatsteak/learningx-alert
```

클론하여 추가 코딩한 경우 원본 URL도 위 저장소로 명시합니다.

## 라이선스

이 프로젝트는 MIT License를 따릅니다.

자세한 내용은 `LICENSE` 파일을 참고하세요.

## 사전 준비

필요한 도구:

- Flutter SDK
- Dart SDK
- Android Studio 또는 Android emulator
- Xcode, iOS 실행이 필요한 경우

상태 확인:

```sh
flutter doctor -v
```

의존성 설치:

```sh
dart pub get
```

## Melos 명령

루트에서 Melos 스크립트를 실행합니다.

스크립트 목록:

```sh
dart run melos run --list
```

정적 분석:

```sh
dart run melos run analyze
```

테스트:

```sh
dart run melos run test
```

JSON serialization 코드 생성:

```sh
dart run melos run build_runner
```

## 앱 실행

Android 에뮬레이터 또는 기기:

```sh
dart run melos run run:android
```

iOS 시뮬레이터 또는 기기:

```sh
dart run melos run run:ios
```

Chrome:

```sh
dart run melos run run:chrome
```

사용 가능한 디바이스 확인:

```sh
flutter devices
```

Melos를 거치지 않고 직접 실행해야 할 경우:

```sh
flutter run -d <device_id> -t apps/learningx_alert/lib/main.dart
```

## 데이터 흐름

앱은 Canvas access token을 저장한 뒤 `LearningXApiClient`로 일정을 동기화합니다.

- 앱 로그인 화면에서 SSU Canvas 로그인 페이지를 엽니다.
- Canvas 세션이 확인되면 access token 생성을 시도합니다.
- 토큰이 저장되면 홈 화면에서 `getUpcomingLearningItems()`를 호출합니다.
- 가져온 일정은 로컬 캐시에 저장됩니다.
- 설정된 알림 시점에 따라 로컬 알림을 예약합니다.

주요 연결 지점:

- API 클라이언트: `packages/learningx_api/lib/src/learningx_api_client.dart`
- 앱 provider 연결: `apps/learningx_alert/lib/src/app_providers.dart`
- 로그인 WebView: `apps/learningx_alert/lib/src/features/login/canvas_token_login_screen.dart`
- 홈 일정 목록: `apps/learningx_alert/lib/src/features/home/home_screen.dart`
- 알림 예약: `apps/learningx_alert/lib/src/notifications/notification_service.dart`
- 설정 화면: `apps/learningx_alert/lib/src/features/settings/settings_screen.dart`

## LearningX API 실서비스 확인

`learningx_api` 패키지는 실제 Canvas/LearningX API에 연결하는 live test를
제공합니다. 토큰이 없으면 live test는 자동으로 skip됩니다.

기본 실행:

```sh
LEARNINGX_ACCESS_TOKEN='canvas-token' dart test packages/learningx_api/test/live_learningx_api_test.dart
```

조회 기간과 출력 개수 조절:

```sh
LEARNINGX_ACCESS_TOKEN='canvas-token' \
LEARNINGX_DAYS_AHEAD=60 \
LEARNINGX_PRINT_LIMIT=50 \
dart test packages/learningx_api/test/live_learningx_api_test.dart
```

다른 Canvas 호스트 사용:

```sh
LEARNINGX_BASE_URL='https://canvas.example.edu' \
LEARNINGX_ACCESS_TOKEN='canvas-token' \
dart test packages/learningx_api/test/live_learningx_api_test.dart
```

live schedule test는 앱이 표시할 일정 데이터를 콘솔에 출력합니다.

```text
LearningX live schedule preview
Base URL: https://canvas.ssu.ac.kr
User: Student Name (12345)
Range: next 14 days
Fetched items: 3

No. | Due | Type | Course | Title
----|-----|------|--------|------
1. | 2026-05-01 23:59 | 과제 | Course Name | Assignment title
```

## 검증 명령 요약

일반 개발 중에는 아래 순서로 확인하면 됩니다.

```sh
dart run melos run build_runner
dart run melos run analyze
dart run melos run test
```

실제 API 일정 데이터를 눈으로 확인할 때는 live test를 실행합니다.

```sh
LEARNINGX_ACCESS_TOKEN='canvas-token' dart test packages/learningx_api/test/live_learningx_api_test.dart
```
