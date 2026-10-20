# AthleteOS MVP hardening — 20 October 2026

## 1. Baseline before changes

Both repositories were clean at backend `8566f64` and Flutter `02f2ddb`.
Backend compilation passed; **73 backend tests passed**. Flutter analysis was clean;
**114 Flutter tests passed**, with the opt-in live-write test skipped.
Existing architecture, authentication, themes and functional MVP were preserved.

## 2. Alembic model registry

`CoachAthlete` is imported/exported by `app.models`. A clean-process test checks all
ten application tables in `Base.metadata`, including `coach_athletes`, preventing
route import order from concealing a missing migration model.

## 3. Fresh database strategy

Added a static baseline captured from inspected PostgreSQL application-table DDL,
including defaults, checks, FKs, indexes and existing uniqueness. It refuses to run
if any application table already exists. Unrelated product tables are outside this
application baseline. No autogenerate was run against development.

Exact fresh-install and adoption commands are in the backend's
`docs/database_bootstrap.md`. `scripts/audit_schema.py` is a read-only preflight
against `docs/schema_contract.json`. It checks columns, types, defaults, nullability,
FKs, checks, unique keys, indexes and duplicate data. Equivalent PostgreSQL text-array
cast representations are normalized without ignoring operators or numeric checks.

## 4. Migrations

- New `0000_initial_schema`: complete guarded pre-auth schema.
- Historical `0001_add_user_password_hash`: its predecessor now points to 0000;
  its upgrade operation is unchanged.
- New `0002_training_invariants`: result uniqueness normalization and partial unique
  open-workout schedule index, with duplicate-data preflight and transactional locking.

Existing databases at 0001 skip the newly inserted ancestor. Fully initialized but
unversioned databases require backup/schema review and a passing audit before stamping
**0001 only**, then upgrading. Never stamp head or bootstrap development to test it.
Automatic baseline/invariant downgrades are intentionally disabled.

## 5. Workout-result uniqueness

The development catalog already had `workout_results_workout_id_athlete_id_key` on
`(workout_id, athlete_id)`. No duplicate result rows existed. Metadata now declares
`uq_workout_results_workout_athlete`. Migration reuses/renames equivalent constraints,
or attaches an equivalent standalone unique index, instead of adding a duplicate.
Existing duplicates stop migration; no automatic deletion occurs. Service conflict
handling still rolls back and returns HTTP 409 `WORKOUT_ALREADY_COMPLETED`.

## 6. Concurrent submission verification

Real disposable PostgreSQL sessions force both submissions past the real precheck
before inserting. Exactly one succeeds and one receives the conflict domain outcome.
The database contains exactly one WorkoutResult and one SetResult for that fixture.
The unique constraint is not mocked. Separate real tests inject failure after set
flush and prove no partial result survives and workout status is unchanged.

## 7. Coach read/lock separation

`CoachRepository.athletes(..., for_update=False)` does not lock ordinary roster/detail
reads. Workout creation explicitly requests the relationship lock. Authorization is
unchanged: only an active, non-ended assignment grants access; unassigned detail is 404.
SQL compilation tests verify the read has no FOR UPDATE and mutation requests do.

## 8. Training calendar policy

Central `scheduling_date()` derives a calendar date from an aware instant using an
explicit IANA zone: `SCHEDULING_TIMEZONE`, default **Asia/Tehran**. Host-local date is
no longer a business rule. Coach creation, Today's Workout and demo scheduling scripts
use this policy. Midnight tests cover Tehran and New York; DST transition tests and
naive-instant rejection also pass. No athlete timezone field exists, so per-athlete
zones remain an immediate v0.2 follow-up. No UTC offset is stored as zone identity.

## 9. One open workout per day

`uq_workouts_athlete_scheduled_open` is a PostgreSQL partial unique index on athlete/date
for `planned`/`active` rows. Completed/cancelled history remains valid. Legacy null
dates remain untouched; new assignments require a date. Same-date conflicts return
409 `WORKOUT_SCHEDULE_CONFLICT`; unrelated integrity failures retain a generic conflict.
Real tests cover first assignment, duplicate rejection, different dates and reopening
a date after completion. Today's lookup uses `scalar_one_or_none`, without LIMIT 1.

## 10. Flutter no-op cleanup

View Plan navigates to the current workout. The notification control is removed.
A widget test checks both behaviors. No notification system or redesign was added.

## 11. Progress scalability

`GET /v1/athletes/me/progress-summary` returns SQL aggregates for completed workouts,
completed sets and prescribed sets, derived completion percentage/grade, and at most
ten recent activities. Recent activity excludes full set-result arrays. Aggregate
queries are athlete-scoped and avoid join multiplication. Real tests cover totals,
partial completion, empty histories, bounded recent activity and authorization.

Flutter Progress uses a dedicated repository/provider for this endpoint. History
fetches one page at a time (20 by default), with explicit Load more. Successful finish
invalidates both caches. Pagination rejects late results after a provider/account
generation changes. Completion grading is retained; no Performance Grading was added.

## 12. CI

- Backend `.github/workflows/backend.yml`: Python 3.12, requirements, compileall,
  pytest including disposable PostgreSQL tests, and Alembic heads. Its PostgreSQL 16
  service is isolated and uses ephemeral trust authentication; no stored password or
  development connection appears in the workflow.
- Flutter `.github/workflows/flutter.yml`: Flutter 3.41.2 stable, dependency install,
  analysis and tests.

Workflows were prepared locally; no commit, push or remote Actions run was initiated
by the agent. Native/device live-write E2E remains opt-in and is not run against
development from CI.

## 13. Backend verification

- Complete suite with disposable integration enabled: **90 passed** (83 other tests
  plus seven PostgreSQL integration tests), one existing Starlette/AnyIO deprecation.
- Final captured rerun, including the expanded adoption test: **90 passed in 408.40s**,
  `PYTEST_EXIT_CODE=0` (`build/hardening-backend-final.log`, ignored build artifact).
- Normal non-integration invocation: **83 passed, seven skipped**.
- Expanded adoption guard/index-reuse/duplicate-preservation test: **one passed**.
- `python -m compileall app scripts`: passed.
- `alembic heads`: `0002_training_invariants (head)`.
- Development `alembic current`: `0001_add_user_password_hash`.

## 14. Flutter verification

`flutter analyze`: clean. `flutter test`: **118 passed**, one opt-in live-write test
skipped. Auth, Coach, Training, Progress and Light/Dark/System regressions remain green.
New tests cover navigation, removed fake controls, summary fetching, invalidation and
explicit history pagination.

## 15. Fresh PostgreSQL verification

Disposable UUID-named databases were created and upgraded using Alembic, then checked
for all ten tables, password_hash, one result identity constraint and the partial
schedule index. Real writes, concurrent results, rollback, aggregate totals and the
authenticated Coach → Athlete API slice passed. The extended adoption test also
proved refusal of populated unversioned bootstrap, safe stamp/upgrade, reuse of an
equivalent standalone index, and duplicate-row preservation.

No bootstrap or hardening migration was applied to the development database. Scratch
databases left by an initial network interruption and failed audit were subsequently
cleaned up by their exact creation UUIDs. Shared application data was untouched.

## 16. Remaining risks and deployment work

- **Apply the reviewed 0002 migration before deploying the new code.** It is tested
  but still pending on development. Schedule a maintenance window: duplicate audits
  and transactional index creation can block writers on a large database.
- The global IANA scheduling zone is explicit; athlete-specific zones and deliberate
  multi-session/day support remain v0.2 decisions.
- GitHub Actions and physical-device secure storage were not exercised remotely.
  The current authenticated Coach → Athlete API flow passed on disposable PostgreSQL;
  Flutter screens/repositories passed their automated suite. Shared-db live-write
  Flutter E2E was deliberately not rerun during this safety-focused sprint.
- An initial database-driver traceback exposed the configured database password in
  tool output. **Rotate that password.** It was not written to source or committed.
  Pytest diagnostics now redact it; no raw password is reproduced in this report.
- Existing ORM declarations still have historical differences from the complete
  database snapshot. Future autogenerate output requires review; the baseline and
  adoption audit do not treat incomplete ORM metadata as schema truth.

No shared database was destructively modified, no existing user data was deleted,
auth security was not weakened, no secrets were added to tracked source, and no v0.2
Performance Grading or unrelated product features were introduced.

## 17. Git state and commands

The agent did not execute commit or push. During work, HEAD advanced externally to
Flutter `084c93d` and backend `ecd117e`; those commits were preserved. Remaining fixes
and this report are left for review. The final full status snapshots follow below.

Backend commands (from `athlete_os_backend`):

```powershell
.\.venv\Scripts\python.exe -m compileall app scripts
.\.venv\Scripts\python.exe -m pytest -q --tb=short
$env:RUN_POSTGRES_INTEGRATION = '1'
.\.venv\Scripts\python.exe -m pytest -q --tb=short
Remove-Item Env:RUN_POSTGRES_INTEGRATION
.\.venv\Scripts\python.exe -m alembic heads
.\.venv\Scripts\python.exe -m alembic current
.\.venv\Scripts\python.exe scripts/audit_schema.py
```

Frontend commands (from `athlete_os`):

```powershell
flutter analyze
flutter test
```

### Final git status snapshots

Flutter HEAD: `084c93d Harden Flutter MVP experience`

```text
On branch main
Your branch is up to date with 'origin/main'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	docs/HARDENING_REPORT.md

nothing added to commit but untracked files present (use "git add" to track)
```

Backend HEAD: `ecd117e Harden backend MVP reliability`

```text
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   app/api/v1/workouts.py
	modified:   app/models/workout.py
	modified:   app/models/workout_result.py
	modified:   app/services/coach_service.py
	modified:   app/services/workout_service.py
	modified:   scripts/audit_schema.py
	modified:   tests/test_postgres_integration.py

no changes added to commit (use "git add" and/or "git commit -a")
```
