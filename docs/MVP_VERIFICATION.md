# AthleteOS MVP verification — 20 October 2026

## A. Baseline audit

Both repositories were clean before editing. Latest frontend commit was `d303a08`;
latest backend commit was `3ebe5b6`. Existing auth, JWT identity, athlete ownership,
Training execution/results/history, exercise UUID/slug handling, nullable prescription
reads, and persisted Light/Dark/System themes were retained.

Baseline verified: backend **44 passed**, Flutter **90 passed**, analysis clean.
Missing: coach APIs/UI, assignment/library API, completion grading, real Progress.
Home also contained fixed dates, demo metrics and invented completion indicators.

## B. Backend

Added authenticated endpoints:

- `GET /v1/coaches/me/athletes`
- `GET /v1/coaches/me/athletes/{athlete_id}`
- `POST /v1/coaches/me/athletes/{athlete_id}/workouts`
- `GET /v1/exercises` (shared authenticated read-only library)

Coach identity comes exclusively from existing JWT auth. Only active, non-ended
`coach_athletes` relationships authorize access. Unassigned athletes return 404.
Roster output explicitly selects public profile fields, with deterministic ordering.
Detail reuses WorkoutRepository/WorkoutService for today's assignment and five recent
completed sessions. The UI labels this as today's assigned workout.

Creation validates exercises, order uniqueness, set numbering, positive order/counts,
nonnegative bounded reps/weight, finite weight, supported explicit units, date and title.
Extra fields (including coach_id) are rejected. The existing live schema requires
non-null target_reps, target_weight and weight_unit, so new prescriptions require them.
Nullable historical prescription reads remain supported; units are never invented.

Workout, exercise and set rows flush and commit together. Any failure rolls back.
The relationship row is locked during assigned-athlete access, including creation.
Real PostgreSQL verification deliberately failed after all rows flushed and confirmed
zero surviving workout/exercise rows. No orphan sets can survive their foreign key.

A Windows local launcher selects the psycopg-compatible event loop before Uvicorn
starts. Direct `uvicorn app.main:app` failed readiness on this Windows environment
with ProactorEventLoop; `scripts/run_server.py` passed.

## C. Flutter

Added a feature-first coach repository, API adapter, Riverpod providers and UI:
Coach Home/roster → Athlete Detail → Create Workout → Assign Workout.
The builder supports multiple library exercises, date, targets, explicit units and notes.
It validates all mounted fields, disables repeat saves, retains form values on failure,
and refreshes athlete detail after success. Existing ApiClient/auth/theming are reused.

Coach and athlete role guards route to their respective shells. Coach Home includes
logout and Light/Dark/System preferences. No generic green styling was introduced.

Athlete Home now shows the actual assignment title and current calendar dates. Demo
nutrition/weight/sleep/readiness metrics and invented exercise completion are removed.
Training now permits partial finish after one completed set. Save failure shows an
inline error, preserves drafts, and allows retry. Concurrent/repeated finish calls are
blocked; a pending save disables sheet actions. RPE can be cleared by toggling it.
Successful saving still invalidates Today and History through the existing controller.

Progress uses all pages of existing workout history for completed workout/set totals,
prescribed totals, weighted overall completion, recent activity and completion grades.
A trend appears only with at least six graded sessions (last three vs preceding three).
Unavailable body metrics, PRs, rankings and benchmarks are omitted.

## D. Completion Grade

`completed_sets / total_prescribed_sets × 100`.
Boundaries: A ≥90; B ≥75; C ≥50; D <50. Empty prescriptions are ungraded.
Grade uses the unrounded value; displayed percentages are formatted separately.
Counts are clamped to valid bounds defensively. Grade measures prescription completion,
not strength or athletic ability. Flutter derives it from history counts; backend
history also exposes derived `completion_percentage` and `completion_grade`.
No redundant database columns were introduced.

## E. Database

Inspected the actual PostgreSQL coach relationship and prescription constraints before
mapping them. Verified target was local `athlete_os` before any writes. No migrations,
table resets, truncations or user deletions were performed.

The clean live Flutter run persisted workout
`9f7d792c-b456-4037-b679-a81e06d3ae4c`. Independent SQL verification confirmed:
status completed; one of two sets; reps 6; actual weight 2.5 kg; RPE 7; grade C / 50%.

Five clearly named demo verification workouts were created during debugging/verification.
Three have completed results. Only the two unfinished fixtures created in this session
were cancelled by exact UUID to avoid resurfacing as today's active assignment:
`780f8943-680a-479e-b5ac-bae62c6f1455` and
`dfce9f34-8cf5-40ac-b9ca-325c29ed22c1`. All other records were preserved.

## F. Tests

- Backend `python -m compileall app scripts`: passed.
- Backend `python -m pytest -q`: **73 passed**, one existing Starlette/AnyIO deprecation warning.
- Flutter `flutter analyze`: clean.
- Flutter `flutter test`: **114 passed**, **1 skipped** (opt-in live-write test).
- Subsequent focused API repository suite: **17 passed**, including all-page history
  loading and strict prescription-denominator parsing.
- Opt-in real HTTP/PostgreSQL Flutter UI test: **1 passed**.
- `git diff --check`: clean in both repositories.

Coverage includes role routing/auth regressions, public roster/detail parsing,
library loading, assignment serialization/validation, light/dark coach rendering,
grade boundaries, history-derived Progress, partial completion, failure preservation,
duplicate submission and backend rollback. Existing athlete ownership tests remain passing.

## G. Real E2E executed

Backend running on localhost:8011 → real coach login in Flutter UI → assigned Ali →
create/assign workout using real library → coach logout → real athlete login in Flutter
UI → exact assigned title/ID and prescription → start → enter 6 reps / 2.5 kg / RPE 7 →
complete one of two sets → partial finish → History → Progress → grade C at 50%.
Light/Dark/System selections were exercised while retaining the coach route.

Separately verified with real demo JWTs: missing auth 401, athlete on coach API 403,
coach on athlete API 403, unassigned athlete 404, duplicate result 409, and backend
history's derived grade. No credentials or tokens were printed.

## H. Remaining limitations and verification scope

- The live run used Flutter's automated widget UI with real HTTP and PostgreSQL.
  Test token storage was in memory; native secure-storage plugins and a physical
  Android/iOS device were not exercised by this run.
- Access to another athlete's workout remains covered by the existing API tests.
  No second real athlete's credentials were used or impersonated.
- Coach detail intentionally shows today's assignment and five recent completions;
  no schedule-management/editor/cancellation UI or advanced workout builder was added.
- Progress loads all history pages for correct totals; large-history aggregation can
  be optimized later. Six sessions are required before a completion trend is shown.
- New coach/progress copy is English; full Persian localization is pending.
- Existing non-MVP Nutrition/Health/Competition/etc. demonstration screens remain
  outside this change. The core Coach → Training → History → Progress flow has no
  mock repository substitution or fabricated metrics.

No auth bypass or fallback secret was added. No secrets were committed. Green remains
semantic; neutral generic primary and Light/Dark/System behavior are preserved.
No commits or pushes were made.

## I. Commands

Backend, from `athlete_os_backend`:

```powershell
.\.venv\Scripts\python.exe -m compileall app scripts
.\.venv\Scripts\python.exe -m pytest -q
.\.venv\Scripts\python.exe scripts/run_server.py --port 8011
```

Frontend, from `athlete_os` (separate terminal):

```powershell
flutter analyze
flutter test
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8011
# Opt-in: creates and partially completes a clearly named local demo workout.
.\scripts\verify_live_mvp.ps1
```

The verification script requires local demo passwords already configured in backend
`.env`; it creates and deletes a temporary definitions file without logging secrets.
Read-only persistence verification, from `athlete_os_backend`:

```powershell
.\.venv\Scripts\python.exe scripts/verify_mvp_persistence.py 9f7d792c-b456-4037-b679-a81e06d3ae4c
```

## Exact changed files

Frontend:

```text
README.md
docs/MVP_VERIFICATION.md
lib/src/app/router/app_router.dart
lib/src/features/coach/application/coach_providers.dart
lib/src/features/coach/data/api_coach_repository.dart
lib/src/features/coach/domain/coach_models.dart
lib/src/features/coach/domain/coach_repository.dart
lib/src/features/coach/presentation/coach_screens.dart
lib/src/features/coach/presentation/create_workout_screen.dart
lib/src/features/home/presentation/screens/home_screen.dart
lib/src/features/progress/domain/progress_metrics.dart
lib/src/features/progress/presentation/screens/progress_screen.dart
lib/src/features/training/application/controllers/workout_session_controller.dart
lib/src/features/training/data/repositories/api_workout_repository.dart
lib/src/features/training/domain/entities/completion_grade.dart
lib/src/features/training/domain/entities/workout_history_entry.dart
lib/src/features/training/presentation/screens/workout_screen.dart
lib/src/features/training/presentation/training_formatters.dart
scripts/verify_live_mvp.ps1
test/api_workout_repository_test.dart
test/auth_test.dart
test/coach_test.dart
test/completion_progress_test.dart
test/live_mvp_test.dart
test/training_submission_test.dart
test/widget_test.dart
```

Backend:

```text
README.md
app/api/deps.py
app/api/v1/coaches.py
app/api/v1/router.py
app/core/completion_grade.py
app/models/coach_athlete.py
app/repositories/coach_repository.py
app/schemas/coach.py
app/schemas/history.py
app/services/coach_service.py
scripts/run_local.ps1
scripts/run_server.py
scripts/verify_mvp_persistence.py
tests/test_coach_api.py
tests/test_completion_grade.py
```
