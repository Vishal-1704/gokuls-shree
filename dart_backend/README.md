# Gokul Shree School — Dart Backend

A lightweight, scalable Dart backend (using `shelf`) that replaces the legacy Node.js Express server.
Built with rigorous security layers and role-based branch isolation.

## 🚀 Getting Started

### 1. Install Dart SDK
Ensure you have the Dart SDK installed (>= 3.0.0).

### 2. Install Dependencies
```bash
cd dart_backend
dart pub get
```

### 3. Environment Variables
Copy `.env.example` to `.env` and configure your Supabase keys:
```bash
cp .env.example .env
```
Ensure you provide the `SUPABASE_SERVICE_KEY` — the backend relies on this for secure server-side admin operations bypassing RLS.

### 4. Run the Server
```bash
# Development (with hot-reload using nodemon or basic dart run)
dart run bin/server.dart
```
The server will start on port `3001` by default.

### 5. Database Migration
Ensure you run `012_fix_schema_bugs.sql` in your Supabase SQL editor to fix the schema issues identified during the backend audit.

## 🛡️ Security Architecture
This backend implements a 10-layer security onion:
1. **CORS whitelist**
2. **Security headers** (Helmet-equivalent)
3. **Request logging** (Morgan-equivalent)
4. **Rate limiter** (in-memory, sliding window)
5. **requireAuth** (JWT validation + profile status checks)
6. **requirePermission** (Role whitelist matrix)
7. **strictBranchGuard** (Server-enforced branch data isolation)
8. **studentSelfGuard** (Own-record isolation for students)
9. **Supabase RLS** (Database-level final defense)
10. **auditLog** (Non-blocking sensitive action recording)
