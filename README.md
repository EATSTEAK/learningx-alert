# LearningX Alert

SSU LearningX/Canvas의 과제와 학습 일정 마감 정보를 가져와 앱에서 확인하고 알림을 예약하는 Flutter 프로젝트입니다.

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
- `apps/learningx_alert`: 사용자 로그인, 일정 목록 표시, 로컬 알림 예약을 담당하는 Flutter 앱입니다.
- `packages/learningx_api`: Canvas API access token을 사용해 사용자 프로필과 planner item을 가져오고, 앱에서 쓰는 `LearningItem` 모델로 변환합니다.

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

## LearningX API 실서비스 확인

`learningx_api` 패키지는 실제 Canvas/LearningX API에 연결하는 live test를 제공합니다. 토큰이 없으면 live test는 자동으로 skip됩니다.

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

## 로그인과 데이터 흐름

앱은 Canvas access token을 저장한 뒤 `LearningXApiClient`로 일정을 동기화합니다.

흐름:
- 앱 로그인 화면에서 SSU Canvas 로그인 페이지를 엽니다.
- Canvas 세션이 확인되면 access token 생성을 시도합니다.
- 토큰이 저장되면 홈 화면에서 `getUpcomingLearningItems()`를 호출합니다.
- 가져온 일정은 로컬 캐시에 저장되고 알림 예약에 사용됩니다.

주요 연결 지점:
- API 클라이언트: `packages/learningx_api/lib/src/learningx_api_client.dart`
- 앱 provider 연결: `apps/learningx_alert/lib/src/app_providers.dart`
- 로그인 WebView: `apps/learningx_alert/lib/src/features/login/canvas_token_login_screen.dart`
- 홈 일정 목록: `apps/learningx_alert/lib/src/features/home/home_screen.dart`

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
