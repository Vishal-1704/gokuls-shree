# Exam & Test Module — Rebuild Documentation

This document covers the full rebuild of the MCQ Test/Exam feature: what was
broken, what changed, what to expect now, and how to walk through it end to
end. It's written so you (or anyone else on the project) can pick this up
cold.

---

## 1. What was broken before

The feature *looked* built — screens existed, a repository existed, tables
existed — but authoring, scheduling, and taking an exam were three
disconnected islands:

| Area | Problem |
|---|---|
| Schema | At least three separate, mutually incompatible definitions of `exam_schedules`/`exam_assignments`/`exam_results` existed across `master_schema.sql` and two patch migrations. Whichever ran first in your actual Supabase project silently "won"; the rest were dead SQL. |
| Question authoring | `QuestionManagerScreen` was a stub — literally `Text('Question manager coming soon.')`. There was no way to add an MCQ question in the app at all, despite the repository having full CRUD for it. |
| Test vs Exam | The scheduler screen just relabeled a button based on role (`isBranchAdmin ? 'Test Scheduler' : 'Exam Scheduler'`) — it never wrote an `assessment_type` to the database. Every schedule was silently the same thing. |
| Grading | `ExamQuizScreen` computed the score **in Dart, in memory**, using a correct-answer key that the API shipped to the client with every question (`correct_option_index`). It never called any repository method to persist a session, an answer, or a result. Nothing about a real attempt was ever saved. A student could also read the correct answers straight out of the network response before answering. |
| Attempted vs Absent | Unanswerable — there was no concept of "who was expected to take this," so there was nothing to compare "who actually took it" against. |
| Results | The student's "My Results" screen queried `exam_results` through an `INNER JOIN` on `exam_sessions.student_id` — a relationship nothing ever populated, so the query returned zero rows *even for manually entered marksheet results that already existed in the table*. |
| Branch scoping | Paper/question lists had no branch filter — every admin saw every paper platform-wide. |

---

## 2. What changed

### Database (2 new migrations — must be run manually)

Run these in the Supabase SQL editor, in order, against your project. Both
are additive: nothing existing is dropped, and existing authored content is
copied forward, not discarded.

**[`supabase/migrations/20240301000003_question_bank_and_papers.sql`](supabase/migrations/20240301000003_question_bank_and_papers.sql)**
- New tables: `question_bank` (MCQs, taggable by course/subject/difficulty),
  `papers` (a question paper — title, `assessment_type` = `test`/`exam`,
  duration, total/pass marks, draft/published status), `paper_questions`
  (join table — lets one question be reused across multiple papers).
- Copies every existing row from `exam_categories` → `papers` and
  `exam_questions` → `question_bank` + `paper_questions`, preserving IDs.
  `exam_categories`/`exam_questions` are left untouched, just no longer used
  by the app.

**[`supabase/migrations/20240301000004_schedules_attempts.sql`](supabase/migrations/20240301000004_schedules_attempts.sql)**
- New tables: `schedules` (a paper assigned to a student/course/batch/branch
  with a start/end window and marking rules), `schedule_roster` (a
  **snapshot** of who was expected to attempt a schedule, taken at creation
  time — this is what makes "who was absent" answerable later, since it
  doesn't silently change if a student's batch changes afterwards),
  `attempts` (one row per student attempt — score, result, timestamps),
  `attempt_answers` (per-question answers, graded).
- Two Postgres functions:
  - `materialize_schedule_roster(schedule_id)` — expands a schedule's
    student/course/batch/branch assignment into concrete `students` rows.
    Called automatically right after a schedule is created.
  - `grade_attempt(attempt_id)` — grades an attempt server-side in one
    transaction: marks each answer correct/incorrect against
    `question_bank`, applies the schedule's marks-correct/wrong/unanswered
    rules, and writes the final score/result onto `attempts`. This replaces
    the old in-memory client-side scoring.
- Patches `exam_results` (the pre-existing manual marksheet table) with the
  columns `admin_repository.dart`'s manual result-entry code already
  assumed existed (`subject_name`, `exam_name`, `marks_obtained`,
  `total_marks`, `grade`, `notes`, `calculated_at`) — it was missing all of
  them, so manual result entry was silently broken too, independent of
  anything to do with MCQs.

### App code

**[`lib/src/features/exams/data/exam_repository.dart`](lib/src/features/exams/data/exam_repository.dart)** — the core rewrite.
- `getAdminPaperSets`/`createPaperSet`/`updatePaperSet`/`deletePaperSet`/`togglePaperSetStatus` now operate on `papers` with correct column names (`title`, `status: 'draft'|'published'`, `assessment_type`) — previously these read `title`/`is_active` columns that never existed.
- `getAdminQuestions`/`addQuestion`/`updateQuestion`/`deleteQuestion` now operate on `question_bank`/`paper_questions`. Removing a question from a paper now only removes the link — the question stays in the bank, reusable in other papers.
- `createExamSchedule` now inserts into `schedules` referencing `papers.id` correctly (previously it referenced a `paper_sets` table nothing ever wrote to), and calls `materialize_schedule_roster` immediately after.
- `startExamSession`/`submitAnswer`/`finishExam` now actually persist: create an `attempts` row, upsert into `attempt_answers` with a real conflict target (previously the upsert had none, so every answer change inserted a new duplicate row instead of updating), and call `grade_attempt` server-side on submission.
- `getQuestions` no longer sends `correct_option` to the client at all — grading moved server-side specifically so the answer key never has to leave the database.
- `getExams`/`getUpcomingExams`/`getMyResults`/`canStartExam` rewritten against the new schema and properly scoped to the current student (resolved via `auth user → profiles.id → students.id`).
- New: `getSchedulesForAdmin`, `getScheduleRoster` (roster joined against attempts → submitted/started/absent), `publishScheduleResults` (pushes submitted scores into the existing marksheet `exam_results` table).

**[`lib/src/features/exams/presentation/question_manager_screen.dart`](lib/src/features/exams/presentation/question_manager_screen.dart)** — was a stub, now a full add/edit/remove MCQ authoring screen (question text, 4 options, correct-answer selector, marks, optional subject tag, easy/medium/hard difficulty).

**[`lib/src/features/exams/presentation/admin_schedule_results_screen.dart`](lib/src/features/exams/presentation/admin_schedule_results_screen.dart)** — new. A list of schedules; tapping one shows the roster split into **Submitted** / **Started, not submitted** / **Absent**, with a **Publish Results** button that pushes every submitted score into the student's marksheet (with an optional checkbox to also record absentees as `AB`).

**[`lib/src/features/exams/presentation/exam_quiz_screen.dart`](lib/src/features/exams/presentation/exam_quiz_screen.dart)** — now starts a real attempt on open, submits each answer as the student picks it, and calls server-side grading on submit instead of computing a score in memory.

**[`lib/src/features/exams/presentation/super_admin_paper_manager_screen.dart`](lib/src/features/exams/presentation/super_admin_paper_manager_screen.dart)** — paper cards now show a real Test/Exam badge and correct published/draft state; the create-paper sheet has a working Test/Exam picker.

**[`lib/src/features/exams/presentation/exam_result_screen.dart`](lib/src/features/exams/presentation/exam_result_screen.dart)** — now accepts the server-computed pass/fail instead of guessing from a hardcoded 40% threshold.

**Student-facing consumers repointed at the fixed data:**
- [`lib/src/core/services/supabase_service.dart`](lib/src/core/services/supabase_service.dart) — `getMyExamResults()` no longer requires a join through `exam_sessions` that nothing populated (this was returning zero rows even for pre-existing manually entered marksheet results).
- [`lib/src/features/student/data/student_repository.dart`](lib/src/features/student/data/student_repository.dart) — mapping updated to the real `exam_results` columns.
- [`lib/src/features/student/presentation/student_test_list_screen.dart`](lib/src/features/student/presentation/student_test_list_screen.dart) (the live "Online Tests"/"Exams" tabs under Academics) and [`student_exam_report_screen.dart`](lib/src/features/student/presentation/student_exam_report_screen.dart) (the "Exam Report" tab) — repointed at the new data shape. The report grid's old columns (attempted/left/correct/wrong/negative-marks) were partially fabricated placeholder math before (`res['negative_marks'] ?? (wrong * 0.25)`); it now shows real Score/Total Marks/Result instead.
- [`lib/src/features/exams/presentation/exam_list_screen.dart`](lib/src/features/exams/presentation/exam_list_screen.dart) — this screen isn't actually routed anywhere reachable in the app, but it had two providers (`upcomingExamsProvider`, `examResultsProvider`) locally shadowing the correct ones from `exam_repository.dart`, silently reading a different, wrong data source. Fixed for whenever it does get wired in.

**Routes:** `/admin/schedule-results` and `/super-admin/schedule-results` added; an "eye"-style action icon on the scheduler screen's app bar opens it directly.

---

## 3. Expected results

- **Authoring:** a super admin can create a paper, mark it Test or Exam, and add real MCQ questions to it (text, 4 options, correct answer, marks, subject, difficulty) — none of this was possible before.
- **Scheduling:** creating a schedule actually links to the paper that was authored, and immediately snapshots the list of students expected to take it.
- **Taking it:** a student's answers are saved as they go (not just held in memory), and submitting produces a real, server-computed score — the correct answers are never sent to the device.
- **Attempted vs Absent:** admins can open any schedule and see exactly who submitted, who started but didn't finish, and who never opened it — a comparison that was previously impossible because nothing recorded who was even supposed to take it.
- **Marks reaching the results screen:** publishing a schedule's results writes them into the same marksheet table the student's existing "My Results"/"Exam Report" screens already read from — which, as a side effect of this fix, means **pre-existing manually entered marks that were silently invisible before now show up too**.
- **Branch scoping:** unaffected papers/questions still show platform-wide today (branch-scoping papers by the paper's own `branch_id` column is there in the schema but not yet enforced in the query — see Known Limitations).

---

## 4. How to walk through it

You'll need three logged-in roles to fully exercise this: **super admin**, **branch admin**, and one **student** account whose `students` row is on the branch/course/batch you'll target. Run the two SQL migrations first (Section 2) — nothing below will work until they're applied.

### A. Author a paper (as super admin)
1. Go to the Exam Paper Manager (`/super-admin/paper-manager`).
2. Tap **+ New Paper**. Give it a title, pick Test or Exam, a course, duration, and total marks. It's created as a **Draft**.
3. Tap the paper's **Questions** action. Add a handful of MCQs (question text, 4 options, mark the correct one, set marks — subject/difficulty are optional).
4. Back on the paper list, tap **Publish** to flip it from Draft to Published. *Only published papers are schedulable.*

### B. Schedule it (as branch admin, for a "Test")
1. Open the scheduler (branch admin's Students tab → Exam Scheduler, titled "Test Scheduler" for this role).
2. Pick the paper you just published, give the schedule a title, a start time, an assignment target (easiest to test with **Per Student**, picking your test student directly), max attempts, and marking rules.
3. Save. This both creates the schedule and immediately snapshots the roster — for a student-type assignment that's just the one student; for course/batch/branch it'll be every matching row in `students`.

### C. Take it (as the student)
1. Go to Academics → **Online Tests** (or **Exams**, matching whichever `assessment_type` you picked). Your scheduled paper should appear once its start time has passed.
2. Start it, answer the questions, submit. You should land on the result screen with a real score — refresh your Supabase `attempts` table and you'll see a `submitted` row with `score`/`total_marks`/`result` filled in, and `attempt_answers` rows per question.
3. Try starting it again if `max_attempts` allows it, or confirm you're blocked once you hit the limit.

### D. Check attempted vs absent, publish results (as the admin who scheduled it)
1. From the scheduler screen's app bar, tap the results icon (or go straight to `/admin/schedule-results` or `/super-admin/schedule-results`).
2. Tap the schedule. You'll see three sections: **Submitted** (your test student, with their score), **Started, not submitted** (empty unless you deliberately abandon one), **Absent** (any other roster student who never opened it — try assigning a schedule to a whole course/batch to see this populate).
3. Tap **Publish Results**. Optionally tick "mark absentees as AB."
4. Log back in as the student and check "My Results" (`/results`) and the Academics → **Exam Report** tab — the published score should now be visible there.

### E. Sanity-check the pre-existing manual entry flow is also fixed
1. As an admin, use **Results Entry** to manually add a subject mark for any student.
2. Log in as that student and confirm it now actually appears in "My Results" — before this fix, it silently never would have, regardless of the MCQ work.

---

## 4a. Follow-up fixes: marking scheme + question images

Two things added after the initial rebuild, in response to direct questions:

**Marking scheme was collected but not applied correctly.** The scheduler
screen already had Enable Negative Marking / Marks Correct / Marks Wrong /
Marks Unanswered fields — but `grade_attempt()` applied them as flat
per-question values, ignoring each question's own `marks` weight set at
authoring time. Fixed: these are now **multipliers** on that question's own
marks (a 2-mark question loses twice as much on a wrong answer as a 1-mark
one). Field labels/helper text in the scheduler updated to say so
explicitly. See the updated `grade_attempt()` in
[20240301000004_schedules_attempts.sql](supabase/migrations/20240301000004_schedules_attempts.sql).

**Question images.** A question can now carry a diagram/image.
[20240301000006_question_images.sql](supabase/migrations/20240301000006_question_images.sql)
adds `question_bank.image_url` and a `question-images` storage bucket
(same pattern as the existing `avatars` bucket). The question form has an
image picker (upload/preview/remove), and the image renders both in the
admin's question list and on the actual question screen a student sees
while taking the exam.

**Math formulas — not done, needs a decision.** Right now question text is
plain text only. There's no LaTeX/math-formula rendering in this app today.
Two ways to support it, with a real tradeoff:
- **Plain text only** — admins type formulas using Unicode symbols (×, ÷, √,
  ², ₂, π, etc.) or just describe them in words. Zero new dependencies,
  works today, but doesn't render fractions, integrals, matrices, etc.
- **Real LaTeX rendering** — add a package (e.g. `flutter_math_fork`) and
  let admins type `$...$` LaTeX in the question text, rendered properly on
  both the authoring preview and the student's screen. Renders correctly,
  but is a new dependency and a small amount of glue code (detect `$...$`
  spans, render them, leave the rest as plain text).

Given math/diagrams together usually cover it — a proper diagram as an
image plus simple Unicode for anything short — I'd default to the first
option unless you're expecting genuinely complex notation (multi-line
equations, matrices) often enough to justify the dependency. Let me know
which way you want it and I'll build it.

## 4b. Code-review fixes: RLS, idempotency, grading correctness, reliability

A follow-up review caught real gaps in the rebuild. All confirmed against
the actual code and fixed — nothing here was a false positive.

**[`20240301000007_rls_and_grading_fixes.sql`](supabase/migrations/20240301000007_rls_and_grading_fixes.sql) — run this too:**
- **RLS was missing entirely** on all 7 new tables. Any authenticated user
  could `GET /rest/v1/question_bank?select=correct_option` and read the
  answer key directly, or `PATCH /rest/v1/attempts` to set their own score.
  Now: every table has RLS + admin/student policies. `question_bank` itself
  is admin-only; students read questions through a new
  `question_bank_public` **view that structurally excludes the
  `correct_option` column** — not hidden by convention, physically not
  there to select, regardless of what a raw API call asks for.
  `attempts` has no student UPDATE policy at all — scoring only happens
  through `grade_attempt` (a `SECURITY DEFINER` function that bypasses RLS
  internally), so there is no longer any row a student can PATCH to change
  their own score.
- **Idempotent result publishing.** `exam_results` gets a `schedule_id`
  column and a partial unique index on `(student_id, schedule_id)`.
  `publishScheduleResults` now does one batched `upsert` instead of one
  `insert` per student in a loop — re-publishing (double-tap, or a genuine
  re-run after a makeup test) updates existing rows instead of creating
  duplicates, and a dropped connection mid-batch can't leave some students
  published and others not.
- **`grade_attempt` correctness fixes:** unanswered-question marks are now
  summed from the *specific* skipped questions' own weights, not the
  paper's average; a `NULL` selected_option is treated as unanswered
  instead of wrong; `submitted_at` is now set by the function itself using
  the database clock, not a value the client sends; and pass/fail is
  computed against the paper's actual current question total, treating the
  paper's `total_marks`/`pass_marks` as expressing a *percentage* rather
  than literal marks (so a paper whose questions sum to 10 still passes at
  33%, not at a literal "33 marks" nothing can reach).
- **Server-side time-window enforcement.** `grade_attempt` now rejects
  (raises an exception) if it's called more than 3 minutes past the
  paper's duration or the schedule's `end_at` — the client's countdown
  timer was always just a UI convenience; this is what actually stops an
  indefinitely backgrounded app from submitting hours later. The 3-minute
  grace absorbs genuine network lag; adjust it if you want a stricter or
  looser cutoff.

**Client-side reliability fixes ([`exam_quiz_screen.dart`](lib/src/features/exams/presentation/exam_quiz_screen.dart), [`exam_repository.dart`](lib/src/features/exams/data/exam_repository.dart)):**
- **Session-start race fixed.** A student could tap an answer before
  `startExamSession()` resolved, silently dropping it (`_attemptId` was
  still null). The quiz screen now shows a blocking "Preparing your
  exam..." overlay until the session is actually ready.
- **Session resumption.** If the app crashes or the battery dies mid-exam,
  reopening it no longer burns the student's only attempt —
  `startExamSession` now finds the existing `in_progress` attempt (if
  still within its time window) and resumes it, restoring previously
  selected answers and correcting the countdown to the real elapsed time
  instead of restarting a fresh full duration.
- **Answer resync before grading.** Each tap fires `submitAnswer` without
  blocking the UI; if one silently failed on a flaky connection, it would
  otherwise be graded as unanswered with no indication to the student.
  Submission now re-sends every currently selected answer once, right
  before calling `finishExam`, as a last-chance flush.
- **App-switch false positives reduced.** Only `AppLifecycleState.paused`
  (actually backgrounded) counts as a switch now, not `inactive` — a
  transient system overlay (incoming call banner, notification shade, a
  permission prompt) fires `inactive` without the student ever leaving the
  app, and was previously counted as a strike. A 3-second grace timer
  before counting also absorbs a quick, accidental switch.
- **Roster refresh for late enrollments.** A schedule's roster was
  snapshotted once, at creation — a student who joined the target
  course/batch/branch afterward would never appear on it (not even as
  "absent"), and would never see the exam in their own list. The Schedule
  Roster screen now has a refresh action that re-runs
  `materialize_schedule_roster` (safe to call repeatedly — it only adds
  missing roster rows, never removes or duplicates existing ones).

## 4c. Second review pass: deadline design flaw, an unauthenticated grading hole, and a visual bug

Checked every claim against the code before touching anything. Two were
exactly right, one was worse than reported, one turned out to already be
fixed, and two didn't hold up (documented as such rather than silently
"fixed").

**Found while checking the deadline point — not something the review caught:**
`grade_attempt` had **no caller-authorization check at all**. Any
authenticated student could call it with someone else's attempt id and
force-grade / close out a different student's still-in-progress exam
early. Fixed: the function now checks the caller is either an admin or the
attempt's own student before doing anything.

**Real, but the actual failure mode was different than described:** a
network blip right at the deadline didn't leave a student with "0 marks" —
the roster screen already correctly showed them as "Started, not
submitted." But the underlying design was still wrong: once `grade_attempt`
rejected a late call, that attempt could never be graded again, even if
every answer had been saved on time and the only problem was the submit
click arriving a few seconds late. Fixed by relocating the anti-cheat
boundary to where it actually belongs: **`attempt_answers` writes are now
blocked once the window closes** (RLS-level, migration
[20240301000008](supabase/migrations/20240301000008_grading_reliability_and_security.sql)),
so a student genuinely cannot save new answers after time is up — but
`grade_attempt` itself no longer has a deadline check, since grading
whatever was legitimately saved is safe no matter when it happens to run.
Added `grade_expired_attempts()`, a sweep function for attempts nobody
ever returns to close out (crashed app, never reopened) — **you need to
schedule this yourself** (pg_cron or any periodic job you already run);
nothing calls it automatically.

**Real:** the client-side countdown was computed from `DateTime.now()` on
the student's device — a skewed device clock could trigger a premature
*local* auto-submit (the server-side deadline check was never actually
vulnerable to this, since it only ever compares two server timestamps to
each other, but the review's framing didn't distinguish the two). Fixed by
adding `attempt_remaining_seconds()`, a function that computes the
countdown entirely server-side; the client now displays that instead of
computing elapsed time from its own clock.

**Real:** the 3-second app-switch grace period was too tight (an incoming
call ringing, a permission prompt) and strikes were never recorded
anywhere for an admin to review. Bumped to 8 seconds, and attempts now
have an `auto_submit_reason` column (`'app_switch'` / `'time_expired'` /
`'auto_swept_expired'`) set by `grade_attempt` itself, shown as a small
flag icon next to the student's name on the roster screen so an admin can
tell a flagged auto-submit apart from a normal one.

**Real, and already-fixed color bug in `exam_quiz_screen.dart`:** the
question card, option cards, and bottom action bar used
`AppColors.textPrimary` (near-black) as a *background fill* — a leftover
assumption from before this app's color palette was migrated from a dark
theme to a light one (the same root cause as the branch-admin dashboard
color bugs fixed earlier in this project). Some of these had already been
corrected by the time this was checked; the remaining ones (bottom nav bar
background, two button foreground colors, the selected-option checkmark)
are fixed now.

**Didn't hold up:**
- The answer-resend loop before submission is `await`ed one at a time in a
  `for` loop, not fired in parallel — there's no connection-pool
  exhaustion happening there.
- Multi-subject marksheets already work: one paper = one subject, so a
  multi-subject exam is authored as separate papers, each scheduled
  independently, producing one `exam_results` row per subject — which is
  what a marksheet needs. If the actual requirement is a *single timed
  sitting* spanning multiple subject sections, that's a real schema change
  worth discussing, not a bug to guess at silently.

**Flagged, not built (a genuine architecture decision, not a quick fix):**
offline-first local answer queueing (Hive/SQLite + background sync) would
make the app more resilient in true zero-connectivity conditions, but it's
a real dependency and design choice — say the word if you want it and
I'll scope it properly rather than bolt it on.

## 5. Known limitations / not done here

- **Branch scoping on papers/questions** — `papers.branch_id` exists in the schema but `getAdminPaperSets()`/the paper list aren't filtered by it yet, so every admin still sees every paper. Same shape of fix as was applied to the branch-admin dashboard stats earlier in this project.
- **Option/question shuffling** — `schedules.shuffle_questions`/`shuffle_options`-equivalent behavior isn't implemented client-side in `ExamQuizScreen`; questions render in a fixed order.
- **No "close schedule" action** — a schedule stays open indefinitely after its `start_at` unless you set an `end_at` when creating it (the current scheduler UI doesn't expose an end-time picker; `createExamSchedule`'s `endAt` parameter is there and optional, wiring a picker into the form is a small follow-up).
- **`exam_list_screen.dart`** is dead code (not routed anywhere) — fixed so it's not actively wrong, but not verified end-to-end since nothing reaches it today.
- **Legacy tables** (`exam_categories`, `exam_questions`, `exam_schedules`, `exam_assignments`, `exam_sessions`, `exam_answers`, `paper_sets`) are left in the database untouched. They're no longer read or written by the app after this change, but nothing has deleted them — worth a separate cleanup pass once you're confident nothing else depends on them.
