/**
 * Gokul Shree School — Production API Server
 * Security layers (outermost → innermost):
 *   1. Helmet (HTTP security headers)
 *   2. CORS whitelist
 *   3. Rate limiter (login: 5/15min, API: 120/min)
 *   4. requireAuth (JWT + profile + status check)
 *   5. requirePermission (role whitelist)
 *   6. strictBranchGuard (branch isolation)
 *   7. studentSelfGuard (own-record only)
 *   8. Supabase RLS (database-level final line of defense)
 *   9. auditLog (every sensitive action recorded)
 */
require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');
const morgan  = require('morgan');

const authRoutes       = require('./routes/auth.routes');
const studentRoutes    = require('./routes/student.routes');
const feeRoutes        = require('./routes/fee.routes');
const attendanceRoutes = require('./routes/attendance.routes');
const documentRoutes   = require('./routes/documents.routes');
const noticeRoutes     = require('./routes/notice.routes');
const courseRoutes     = require('./routes/course.routes');
const downloadRoutes   = require('./routes/download.routes');
const branchRoutes     = require('./routes/branch.routes');

const { loginLimiter } = require('./middleware/rate.limiter');

const app = express();
const API = `/api/${process.env.API_VERSION || 'v1'}`;

// ── 1. Helmet — secure HTTP headers ──────────────────────────────────────
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));

// ── 2. Trust proxy — needed for correct IP on Render.com ─────────────────
app.set('trust proxy', 1);

// ── 3. CORS ───────────────────────────────────────────────────────────────
const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',').map(s => s.trim()) || ['*'];
app.use(cors({
  origin: allowedOrigins.includes('*') ? '*' : (origin, cb) => {
    if (!origin || allowedOrigins.includes(origin)) return cb(null, true);
    cb(new Error(`CORS: ${origin} not allowed`));
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  exposedHeaders: ['X-RateLimit-Limit', 'X-RateLimit-Remaining'],
}));

// ── 4. Request logging ────────────────────────────────────────────────────
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// ── 5. Body parser ────────────────────────────────────────────────────────
app.use(express.json({ limit: '5mb' }));  // 5mb max — enough for photos
app.use(express.urlencoded({ extended: true, limit: '5mb' }));

// ── 6. Security headers — extra ────────────────────────────────────────────
app.use((_req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('Referrer-Policy', 'no-referrer');
  next();
});

// ════════════════════════════════════════════════════════════════
// HEALTH CHECKS — public, no auth (used by Render.com + cron)
// ════════════════════════════════════════════════════════════════
app.get('/',       (_req, res) => res.json({ app: 'Gokul Shree API', version: process.env.API_VERSION || 'v1', status: 'online' }));
app.get('/health', (_req, res) => res.json({ status: 'ok', timestamp: new Date().toISOString(), env: process.env.NODE_ENV }));
app.get('/ping',   (_req, res) => res.send('pong'));

// ════════════════════════════════════════════════════════════════
// AUTH ROUTES — public (login, refresh)
// Login has its own rate limiter (5 attempts per 15 min per IP)
// ════════════════════════════════════════════════════════════════
app.use(`${API}/auth`, loginLimiter, authRoutes);

// ════════════════════════════════════════════════════════════════
// PROTECTED API ROUTES
// Each route module handles requireAuth + role checks internally.
// Rate limiting is applied inside each router module.
// ════════════════════════════════════════════════════════════════
app.use(`${API}/students`,   studentRoutes);
app.use(`${API}/fees`,       feeRoutes);
app.use(`${API}/attendance`, attendanceRoutes);
app.use(`${API}/documents`,  documentRoutes);
app.use(`${API}/notices`,    noticeRoutes);
app.use(`${API}/courses`,    courseRoutes);
app.use(`${API}/downloads`,  downloadRoutes);
app.use(`${API}/branches`,   branchRoutes);

// ════════════════════════════════════════════════════════════════
// 404 — unknown route
// ════════════════════════════════════════════════════════════════
app.use((req, res) => {
  res.status(404).json({ error: `Route ${req.method} ${req.path} not found` });
});

// ════════════════════════════════════════════════════════════════
// GLOBAL ERROR HANDLER
// Never leak stack traces to client in production
// ════════════════════════════════════════════════════════════════
app.use((err, req, res, _next) => {
  const isDev = process.env.NODE_ENV !== 'production';

  // Log the full error server-side always
  console.error(`💥 Unhandled Error | ${req.method} ${req.path} |`, err.message);
  if (isDev) console.error(err.stack);

  // CORS error
  if (err.message?.includes('CORS')) {
    return res.status(403).json({ error: 'Cross-origin request blocked' });
  }

  res.status(err.status || 500).json({
    error: isDev ? err.message : 'Internal server error',
    ...(isDev && { stack: err.stack }),
  });
});

// ════════════════════════════════════════════════════════════════
// START
// ════════════════════════════════════════════════════════════════
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n🚀 Gokul Shree API — Port ${PORT}`);
  console.log(`📍 NODE_ENV   : ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔗 Supabase   : ${process.env.SUPABASE_URL ? '✅' : '❌ MISSING'}`);
  console.log(`📡 API Base   : ${API}`);
  console.log(`\n🛡️  Security layers active:`);
  console.log(`   ✅ Helmet HTTP headers`);
  console.log(`   ✅ CORS (origins: ${allowedOrigins.join(', ')})`);
  console.log(`   ✅ Rate limiter (login: 5/15min | API: 120/min)`);
  console.log(`   ✅ JWT auth + profile status check`);
  console.log(`   ✅ Role permission matrix`);
  console.log(`   ✅ Branch isolation (server-enforced)`);
  console.log(`   ✅ Student self-guard`);
  console.log(`   ✅ Audit logging\n`);
});

module.exports = app;
