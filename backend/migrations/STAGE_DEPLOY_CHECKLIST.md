# Staged Migration Deploy Checklist

## Scope

- Stage 1: `stage_01_smart_attendance_qr_ble.sql`
- Stage 2: `stage_02_exam_scheduler_visibility.sql`

Apply in order and verify each stage before moving to next.

## 1. Pre-flight Checks

1. Take a DB backup/snapshot.
2. Confirm you are connected to the correct Supabase project and schema (`public`).
3. Ensure no active DDL changes are running in parallel.

## 2. Apply Stage 1 (Smart Attendance)

Run:

```sql
-- Stage 1
\i backend/migrations/stage_01_smart_attendance_qr_ble.sql
```

If running in Supabase SQL Editor, paste and execute the file content directly.

### Stage 1 Verification

```sql
-- tables
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'attendance_settings',
    'attendance_qr_sessions',
    'attendance_ble_events',
    'attendance_events'
  )
order by table_name;

-- view
select table_name
from information_schema.views
where table_schema = 'public'
  and table_name = 'v_attendance_daily';
```

## 3. Apply Stage 2 (Exam Scheduling + Visibility)

Run:

```sql
-- Stage 2
\i backend/migrations/stage_02_exam_scheduler_visibility.sql
```

### Stage 2 Verification

```sql
-- tables
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('exam_schedules', 'exam_assignments')
order by table_name;

-- exam_sessions columns
select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'exam_sessions'
  and column_name in ('exam_schedule_id', 'attempt_no', 'option_shuffle_seed', 'submitted_at')
order by column_name;

-- triggers
select trigger_name, event_object_table
from information_schema.triggers
where trigger_schema = 'public'
  and trigger_name in (
    'trg_exam_schedule_enforce_shuffle',
    'trg_exam_schedule_derive_end_at'
  )
order by trigger_name;

-- visibility view
select table_name
from information_schema.views
where table_schema = 'public'
  and table_name = 'v_student_visible_exams';
```

## 4. Smoke Tests

### 4.1 Scheduler

1. Create one schedule assigned to a specific student.
2. Create one schedule assigned by course/batch/branch.
3. Confirm `end_at` auto-derives from `start_at + duration_minutes`.

```sql
select id, title, start_at, end_at, duration_minutes, max_attempts, shuffle_options
from exam_schedules
order by id desc
limit 10;
```

### 4.2 Student Visibility

```sql
-- replace with a real student uuid
select *
from v_student_visible_exams
where student_id = 'REPLACE_STUDENT_UUID'
order by start_at;
```

### 4.3 Attempt Limit

1. Start exam until max attempts reached.
2. Confirm UI blocks further attempts.
3. Confirm DB session counts align.

```sql
-- replace values
select exam_schedule_id, student_id, count(*) as attempts
from exam_sessions
where exam_schedule_id = REPLACE_SCHEDULE_ID
  and student_id = 'REPLACE_STUDENT_UUID'
group by exam_schedule_id, student_id;
```

## 5. Rollback Strategy (Minimal)

If Stage 2 fails post-deploy:

1. Disable scheduler UI route temporarily.
2. Revert app to legacy paper-set flow.
3. Keep Stage 1 tables (non-breaking) unless they are proven problematic.

For full rollback, restore from snapshot.

## 6. Post-Deploy App Checks

1. Admin can open Exam Scheduler and create schedules.
2. Student sees only assigned visible exams.
3. Attempt limit and schedule window are enforced from instructions screen.
4. Existing legacy exams continue to load through fallback query.
