# learningx_api

Canvas/LearningX API client used by the `learningx_alert` Flutter app.

The default endpoint is SSU Canvas: `https://canvas.ssu.ac.kr`.

## Package layout

- `lib/learningx_api.dart`: public package exports.
- `lib/src/learningx_api_client.dart`: authenticated Canvas API client.
- `lib/src/*_item.dart`: JSON models for users, planner rows, and app-facing learning items.
- `test/learningx_api_test.dart`: offline unit tests.
- `test/live_learningx_api_test.dart`: optional live tests against the real Canvas web API.

## Usage

```dart
final api = LearningXApiClient(accessToken: accessToken);
final profile = await api.getSelfProfile();
final items = await api.getUpcomingLearningItems(daysAhead: 60);
```

## Live API testing

Live tests are skipped by default. To test this package against the real SSU Canvas API, provide a Canvas access token:

```sh
LEARNINGX_ACCESS_TOKEN='canvas-token' dart test packages/learningx_api/test/live_learningx_api_test.dart
```

To use another Canvas-compatible endpoint:

```sh
LEARNINGX_BASE_URL='https://canvas.example.edu' \
LEARNINGX_ACCESS_TOKEN='canvas-token' \
dart test packages/learningx_api/test/live_learningx_api_test.dart
```

The live test verifies that the token can load the current Canvas profile and that planner item requests can be made through `LearningXApiClient`.

The schedule test also prints a preview table so the app-facing deadline data can be checked visually:

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

Use `LEARNINGX_DAYS_AHEAD` to change the fetch window and `LEARNINGX_PRINT_LIMIT` to change how many rows are printed.
