# Project Requirements

## Platforms & access (stated 2026-09-26)
- Only the **super_admin** role may use the web build. Every other role (student, teacher, branch_admin) is rejected at sign-in on web and must use the mobile app.
- On web, super_admin has full administrator access — every admin form/feature, including all branch-admin screens.
- No splash screen on web.

## Superadmin web UI (stated 2026-09-26)
- The web UI is a **separate desktop-first admin presentation**, not the mobile UI widened.
- Shared between mobile and web: models, repositories, providers/state, validation, permissions, business rules.
- Web-specific: navigation (persistent sidebar), page layouts, data tables, filters/search, side/detail panels, desktop dialogs. No bottom sheets, no full-width stretched mobile cards, no full-bleed mobile pages with back arrows.
- Mobile UI must keep working unchanged.
- Existing light slate palette (`AppColors`) stays.

## Hosting
- Web is hosted free on Cloudflare Pages (git-connected, `main` branch), secrets injected via Pages environment variables into `.env` at build time.
