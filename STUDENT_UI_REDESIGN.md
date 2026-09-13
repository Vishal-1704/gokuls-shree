# Student UI Redesign — mockups & rationale

Current state (from screenshots): correct-but-flat. Every screen is the same
white-card-on-grey-scaffold pattern, no visual hierarchy, no personality, no
motion cues, no color beyond one blue accent + status chips. For a student
audience this reads like an admin back-office, not an app they open daily.

Design direction: keep the existing light theme + sky-blue token
(`AppColors.goldCta`, `0xFF0EA5E9`) as the anchor color — don't fight the
theme system — but add **one accent gradient per section** (attendance =
green, fees = amber, exams = violet, docs = blue) so screens are
recognizable by color at a glance, add a hero stat instead of a wall of
equal-weight cards, and replace flat icon-in-a-box quick actions with
something that has depth/motion potential.

---

## 1. Dashboard — hero + streak, not a static ID card

```
┌─────────────────────────────────────┐
│ GOKULSHREE               🔔③        │
│ Hey Sakshi 👋                        │
│                                       │
│ ╭───────────────────────────────╮   │
│ │ 🔥 4-day streak      ✦ 82 pts  │   │  ← NEW: gamified header strip
│ ╰───────────────────────────────╯   │
│                                       │
│ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓   │
│ ┃ 🎓 SAKSHI SHARMA               ┃   │
│ ┃    ADCA · Batch 2026-27        ┃   │
│ ┃ ▢▢▢▢▢▢▢▢▢▢  ⬚ scan to verify   ┃   │  ← ID card, QR corner not a
│ ┃ REG  GOKUL0560323              ┃   │    separate hidden screen
│ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛   │
│                                       │
│  Quick Actions                       │
│ ┌───────────┐ ┌───────────┐         │
│ │ 🟢 82%    │ │ 🏆 91%    │         │
│ │ Attendance │ │ Last Result│        │
│ └───────────┘ └───────────┘         │
│ ┌───────────┐ ┌───────────┐         │
│ │ 🟣 Next:  │ │ 🔵 3 new  │         │
│ │ Mon 10 AM │ │ Notices   │         │
│ └───────────┘ └───────────┘         │
└─────────────────────────────────────┘
```

Fee Status is dropped from the dashboard grid per your call — it's still
one tap away from Account → Financial Overview, just not competing for
attention on the home screen. **Last Result** replaces it, backed by real
data already flowing (`exam_results`, built in the MCQ module —
`getMyExamResults()` in `supabase_service.dart:467`): most recent
`percentage`/`status` (pass/fail), tapping opens the existing exam-report
screen. Motivational framing is free — `🏆` on a pass, a gentler `📈` +
"Keep going" on a fail/low score, rather than a flat number.

- Each quick-action card now shows a **live number**, not just an icon +
  label — attendance %, latest exam score, next class, unread count. Turns
  4 identical buttons into 4 different reasons to tap.
- Streak strip is the one genuinely "fun" element — cheap to build
  (`students` has no streak column yet, per the schema check — this needs
  either a new column+trigger on attendance, or drop it. Flag, don't fake
  it with a hardcoded 4).

## 2. Academics Hub — card-grid launcher (decided: Option A)

Correction against the real code (`student_academics_screen.dart`): this
is **5 tabs**, not 3 — `Online Tests | Exams | Exam Report | Study
Material | Documents` — and Documents is itself 3 stacked sections
(Admit Cards, Marksheets, Certificates via `MyDocumentsBody`), matching
what you're describing. 5 equal-weight text tabs in a scrollable
`TabBar` is worse than my first draft assumed — half of them are
scrolled off-screen unlabeled until you swipe the tab strip itself.

Same fix, correctly scoped: kill the tab bar, land on one screen of 5
tappable sections (Documents expands to reveal its own 3 sub-cards, since
"Documents: 0" hides real structure a student cares about — an empty
admit card vs. a ready certificate are different things to check).

```
┌─────────────────────────────────────┐
│         Academics Hub                │
│                                       │
│ ┏━━━━━━━━━━━━━━━┓ ┏━━━━━━━━━━━━━━━┓ │
│ ┃ 📝            ┃ ┃ 🎯            ┃ │
│ ┃ Online Tests  ┃ ┃ Exams         ┃ │
│ ┃ 2 available   ┃ ┃ 1 upcoming    ┃ │
│ ┗━━━━━━━━━━━━━━━┛ ┗━━━━━━━━━━━━━━━┛ │
│ ┏━━━━━━━━━━━━━━━┓ ┏━━━━━━━━━━━━━━━┓ │
│ ┃ 📊            ┃ ┃ 📚            ┃ │
│ ┃ Exam Report   ┃ ┃ Study Material┃ │
│ ┃ Best: 91%     ┃ ┃ 0 files       ┃ │
│ ┗━━━━━━━━━━━━━━━┛ ┗━━━━━━━━━━━━━━━┛ │
│                                       │
│  Documents                            │
│ ┌───────┐ ┌───────┐ ┌───────┐        │
│ │ 🎫 0  │ │ 📄 0  │ │ 🛡️ 0  │        │
│ │ Admit │ │ Marks-│ │ Cert- │        │
│ │ Card  │ │ sheet │ │ ificate│       │
│ └───────┘ └───────┘ └───────┘        │
└─────────────────────────────────────┘
```

- Top 4 cards → `StudentTestListGrid(assessmentType: 'test'|'exam')`,
  `StudentExamReportGrid`, Study Material's existing empty-state screen —
  each already exists, this only changes how you get there (tap a card,
  not swipe a tab strip).
- Documents gets its own row of 3 smaller cards instead of being buried
  as one more equal-weight tile — each opens straight to that one list
  (Admit Cards / Marksheets / Certificates) instead of landing on
  `MyDocumentsBody`'s combined scroll and making the student scroll past
  two empty sections to reach the one they want.
- All counts are real (`getMyMarksheets().length`, `getMyCertificates
().length`, exam schedule/roster counts) — no placeholder numbers.

## 3. Account/Profile — identity card, entry point not inline data

```
┌─────────────────────────────────────┐
│         ╭─────────╮                  │
│         │    S    │  ← Hero avatar,  │
│         ╰─────────╯    initial-based │
│        Sakshi Sharma                 │
│        ⟨ STUDENT ⟩                   │
│                                       │
│  ✉  gokulshreeschool@gmail.com       │
│  🎓  ADCA · GOKUL0560323             │
│  🏫  Branch: Gokul Shree Main        │
│                                       │
│  ┌─────────────────────────────┐    │
│  │ 💳  Fee Status          ›   │    │  ← single entry point,
│  │     View installments & pay │    │    no inline paid/due numbers
│  └─────────────────────────────┘    │
│                                       │
│  ⎋  Sign Out                         │
└─────────────────────────────────────┘
```

Per your call: the inline "Financial Overview" paid/due mini-summary is
removed from this screen entirely — no duplicate numbers rendered here.
`account_screen.dart` already has a working `_buildMenuTile('Detailed Fee
Status', ...)` linking to the real `/fee-status` route
(`student_fee_status_screen.dart` — full installment list, paid/pending/
overdue chips, receipt/pay-now actions, already built). The fix is
deleting the inline `Consumer`/`_buildFinancialStat` block above it and
keeping only that one tile, so Account becomes purely an identity +
navigation screen, and Fee Status stays the one screen that actually shows
money.

- Header name now correctly pulls `profiles.full_name` (already fixed) —
  no more "gokulshreeschool" as a person's name.
- Course/Reg No now genuinely populate (also fixed) instead of showing
  "Pending" forever.

---

## What I will NOT build speculatively
- Streak/points system — no backing column exists; flagging it rather
  than faking a number is the honest move (ponytail: don't invent data).
- Animations beyond what `AnimatedContainer`/`Hero` already give for free —
  a full motion library is over-scoping a one-role UI pass.

## Build order
1. Dashboard: Fee Status quick-action → Last Result card (`exam_results`
   already exists and is queried — a card swap, not new data).
2. Academics Hub: Option A card-grid launcher (routing change, reuses
   existing list screens as-is).
3. Account: delete the inline Financial Overview block, keep only the
   "Fee Status" menu tile pointing at `/fee-status`.
4. Empty-state copy pass across whichever screens still show a bare
   "No X found".
5. Only then: discuss whether a streak/points system is worth a real
   schema addition.
