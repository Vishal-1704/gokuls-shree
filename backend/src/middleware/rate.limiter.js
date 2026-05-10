/**
 * RATE LIMITER MIDDLEWARE
 * Prevents brute-force attacks on login and API abuse.
 *
 * Uses in-memory store (fine for single-process Render.com free tier).
 * No external Redis needed.
 */

// Simple in-memory rate limit store
// Map<key, { count, resetAt }>
const store = new Map();

/**
 * createLimiter(options)
 * @param {number} windowMs   - Time window in ms
 * @param {number} max        - Max requests per window
 * @param {string} message    - Error message
 * @param {function} keyFn    - Function to extract key from req (default: IP)
 */
function createLimiter({ windowMs = 60_000, max = 60, message = 'Too many requests', keyFn } = {}) {
  return (req, res, next) => {
    const key = keyFn ? keyFn(req) : req.ip;
    const now = Date.now();

    let entry = store.get(key);
    if (!entry || now > entry.resetAt) {
      entry = { count: 0, resetAt: now + windowMs };
      store.set(key, entry);
    }

    entry.count++;

    res.setHeader('X-RateLimit-Limit', max);
    res.setHeader('X-RateLimit-Remaining', Math.max(0, max - entry.count));
    res.setHeader('X-RateLimit-Reset', Math.ceil(entry.resetAt / 1000));

    if (entry.count > max) {
      console.warn(`🚫 RATE LIMIT HIT | Key: ${key} | Count: ${entry.count}`);
      return res.status(429).json({
        error: message,
        retry_after_seconds: Math.ceil((entry.resetAt - now) / 1000),
      });
    }

    next();
  };
}

// Clean up expired entries every 5 minutes (prevent memory leak)
setInterval(() => {
  const now = Date.now();
  for (const [key, val] of store.entries()) {
    if (now > val.resetAt) store.delete(key);
  }
}, 5 * 60 * 1000);

// ── Pre-configured limiters ───────────────────────────────────────────────

// Login: 5 attempts per 15 minutes per IP
const loginLimiter = createLimiter({
  windowMs: 15 * 60_000,
  max: 5,
  message: 'Too many login attempts. Please try again in 15 minutes.',
});

// General API: 120 req/min per authenticated user (by profile ID)
const apiLimiter = createLimiter({
  windowMs: 60_000,
  max: 120,
  message: 'API rate limit exceeded. Please slow down.',
  keyFn: (req) => req.profileId || req.ip,
});

// Strict limiter for sensitive ops (approve, generate cert): 20/min
const sensitiveLimiter = createLimiter({
  windowMs: 60_000,
  max: 20,
  message: 'Too many sensitive operations. Please slow down.',
  keyFn: (req) => req.profileId || req.ip,
});

module.exports = { createLimiter, loginLimiter, apiLimiter, sensitiveLimiter };
