# Gokul Shree App - Complete UI/UX Design Brief

## 1. Project Overview

### Product
Gokul Shree is a role-based education platform mobile app with three experience layers:
- Public/Guest experience (discovery, programs, admissions entry)
- Student experience (dashboard, exams, results, fees, documents)
- Admin experience (operations, student management, notices, reports)

### Design Goal
Create a modern, scalable UI system and screen architecture that supports:
- Separate patterns by role
- Native exam experience (no web dependency for core exam flow)
- Dual theme support (light and dark)
- Data-rich dashboards with strong readability and clear interaction states

---

## 2. Final Product Decisions (Locked)

1. Theme strategy:
- Light and dark themes both supported for all roles.
- First launch default: app default theme.

2. Exam platform strategy:
- Full native exam portal entry and authentication in app.
- Website/webview is not the primary exam flow.

3. Priority for design and implementation:
- Student dashboard and student exam flow first.

4. Navigation strategy:
- Separate navigation patterns by role (Guest, Student, Admin).

5. Exam retry behavior:
- Retry action hidden unless backend explicitly returns allow_retake true.

6. During exam back navigation policy:
- Hard blocked (system back and app back both blocked).

---

## 3. Users and Roles

### Guest
- Not logged in
- Needs trust, program discovery, and conversion to login/registration

### Student
- Logged in with student role
- Needs daily academic actions and exam lifecycle tools

### Admin
- Logged in with admin role (super_admin/branch_admin)
- Needs operational controls and reporting workflows

---

## 4. Information Architecture

## 4.1 Guest IA

### Primary Areas
- Home
- Academics & Programs
- Contact / Centre Finder
- Login / Registration entry points

### UX Intent
- Conversion-first, trust-first
- Lightweight navigation and clear calls to action

## 4.2 Student IA

### Primary Navigation (Bottom Nav)
- Dashboard
- Exams
- Profile

### Secondary High-Value Flows
- Fee Status
- Documents
- Results history
- Notices and calendar

### UX Intent
- Task-focused, high-frequency usage
- Fast access to exam and performance information

## 4.3 Admin IA

### Primary Navigation
- Admin Home
- Student Directory
- Scanner/utility
- Admin Menu/Panel

### Secondary Flows
- Results entry
- Add student
- Dues report
- Marksheet generation
- Study material upload
- Notices and staff tools

### UX Intent
- Operational efficiency, bulk action speed, reporting visibility

---

## 5. Core Feature Architecture

## 5.1 Student Dashboard Architecture (P0)

### Required Sections
1. Personalized header (name, date, quick utility)
2. Student identity card
3. Attendance summary
4. Upcoming exam schedule
5. Recent exam results
6. Quick actions grid
7. Fee snapshot
8. Achievement/engagement widgets
9. Academic calendar
10. Notice board
11. Centre/support info

### Data Characteristics
- Multi-source aggregation
- Frequent loading and empty states
- Status-led visual hierarchy (exam, fee, result urgency)

## 5.2 Native Exam Architecture (P0)

### End-to-End Flow
1. Exam list
2. Exam detail and eligibility
3. Instructions and consent
4. Start session
5. Quiz runner (timed)
6. Submit confirmation
7. Result summary
8. Result details/history

### Attempt-Level Constraints
- Hard back block while attempt is active
- Tab switching disabled during attempt
- Exit only via controlled action

### Retake Rules
- Hidden by default
- Only visible if backend response explicitly allows reattempt

---

## 6. Screen Inventory for UI/UX Delivery

## 6.1 Guest Screens
1. Public Home
2. Academics & Features
3. Program details sheet
4. Contact
5. Centre finder
6. Login entry

## 6.2 Student Screens (P0 first)
1. Student Dashboard
2. Exam List (Available / My Results)
3. Exam Instructions
4. Exam Attempt (Question runner)
5. Exam Submit confirmation
6. Exam Result summary
7. Exam Result details
8. Theme Settings (in profile/settings)

## 6.3 Student Screens (P1)
1. Fee Status
2. Documents list
3. Marksheet preview/download
4. Certificate preview/download
5. Profile account screen

## 6.4 Admin Screens
1. Admin Dashboard Home
2. Student directory
3. Admin panel tabs
4. Results entry
5. Add student
6. Dues report
7. Marksheet generator
8. Study material upload
9. Admin notices

---

## 7. Role-Based Navigation Patterns

## 7.1 Guest Pattern
- Minimal 2-tab pattern (Home, Academics)
- Conversion CTA persistent

## 7.2 Student Pattern
- Utility 3-tab pattern (Dashboard, Exams, Profile)
- Exam and dashboard prominence

## 7.3 Admin Pattern
- Dense operational tab pattern
- Fast action tiles + data modules

Design note: Do not unify all roles into one nav model. Keep distinct behavior and visual hierarchy per role.

---

## 8. Theme and Design System Requirements

## 8.1 Theme Model
- Support light and dark for all role experiences
- First launch uses app default theme
- User can change theme in settings/profile
- Theme preference persists across sessions

## 8.2 Token Requirements
- Semantic color tokens for both modes
- Consistent spacing and radius scale
- Typography hierarchy for dense data screens
- Status tokens for success/warning/error/info

## 8.3 Accessibility Requirements
- WCAG-level contrast on both themes
- Touch targets >= 44dp
- No color-only status communication
- Text scaling support

---

## 9. Exam UX Rules (Strict)

## 9.1 Back Handling During Attempt
- Block system back and app back completely
- Show controlled modal on attempted exit
- Modal actions:
  - Continue Exam
  - Submit and Exit

## 9.2 Navigation Lock During Attempt
- Disable bottom nav tab change
- Disable route pop
- Restore navigation only after submit/completion

## 9.3 Retry CTA Rule
- Show reattempt button only when backend says allowed
- If missing or false, do not show any retry action

---

## 10. UX State Matrix (All Important Screens)

Each screen must define and design these states:
1. Initial loading
2. Refresh loading
3. Empty state
4. Error state (with retry)
5. Offline/degraded state
6. Permission/access denied (role mismatch)

Exam-specific states:
1. Time warning
2. Auto-submit on timeout
3. Network interruption handling
4. Resume logic (if supported by backend)

---

## 11. Backend and Data Constraints for Designer

### Primary App Data Layer
- Supabase auth and table-driven repositories
- Student dashboard data is aggregated from multiple entities

### Existing Exam Data Model
- Paper sets
- Questions
- Exam sessions
- Answers
- Results

### Legacy Web Context
- Website has historical Online Exam links
- App direction is now native exam as primary

Design implication: Avoid web-form metaphors for core exam UI. Use native mobile exam patterns.

---

## 12. Deliverables Required from UI/UX Designer

## 12.1 Strategy Deliverables
1. Role-based sitemap (Guest, Student, Admin)
2. End-to-end student exam user flow
3. Navigation behavior map by role

## 12.2 System Deliverables
1. Dual-theme design tokens
2. Component library (cards, chips, forms, nav, sheets, states)
3. Interaction patterns (transitions, confirmations, blocking states)

## 12.3 Screen Deliverables
1. High-fidelity screens for all P0 student dashboard + exam flows
2. Responsive constraints for small and large phones
3. Annotated behavior specs for edge/error states

## 12.4 Prototype Deliverables
1. Clickable prototype for full exam journey
2. Back-block behavior simulation during exam
3. Conditional retry CTA simulation based on backend flag

---

## 13. Acceptance Checklist

Design handoff is considered complete when:
1. All P0 student screens are delivered in light and dark variants
2. Exam flow includes strict navigation lock and hard back-blocking behavior
3. Retry visibility logic is documented as backend-controlled
4. Role-separated navigation patterns are fully specified
5. Loading/empty/error states are present for every data screen
6. Tokens and components are reusable and implementation-ready

---

## 14. Implementation Notes for Engineering Alignment

1. Keep role guards at router/auth layer.
2. Keep exam session state central to control nav lock.
3. Keep retry logic in API contract and view model mapping.
4. Add theme preference persistence in profile/settings local storage.
5. Maintain a single source of truth for design tokens.

---

## 15. Immediate Next Build Order

Phase 1 (highest impact):
1. Student Dashboard redesign (dual theme)
2. Native Exam list -> instruction -> attempt -> result flow
3. Back-block and nav-lock behavior implementation

Phase 2:
1. Fee/documents/profile refinements
2. Admin visual consistency updates
3. Guest conversion optimization

---

This file is the single source handoff brief for UI/UX design and product-aligned implementation.
