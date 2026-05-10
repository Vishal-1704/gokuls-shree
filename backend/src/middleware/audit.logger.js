/**
 * AUDIT LOGGER MIDDLEWARE
 * Records every sensitive action to the `audit_logs` table in Supabase.
 * Provides a full trail: who did what, when, from which IP.
 *
 * Usage: router.patch('/approve', requireAuth, auditLog('APPROVE_MARKSHEET'), handler)
 */
const { supabase } = require('../config/supabase');

/**
 * auditLog(action)
 * Logs to `audit_logs` table AFTER the route handler responds.
 * If DB write fails, we log to console but don't fail the request.
 */
const auditLog = (action) => async (req, res, next) => {
  // Capture original json method to intercept response status
  const originalJson = res.json.bind(res);
  let responseStatus = 200;

  res.json = function (body) {
    responseStatus = res.statusCode;
    return originalJson(body);
  };

  // Continue to handler first
  next();

  // After handler, write audit record asynchronously (non-blocking)
  setImmediate(async () => {
    try {
      await supabase.from('audit_logs').insert({
        action,
        profile_id:   req.profileId  || null,
        role:         req.role        || null,
        branch_id:    req.queryBranchId || req.branchId || null,
        ip_address:   req.ip,
        user_agent:   req.headers['user-agent'] || null,
        request_path: req.originalUrl,
        request_method: req.method,
        response_status: responseStatus,
        payload_summary: JSON.stringify({
          params: req.params,
          // Never log passwords or tokens
          body: sanitizeBody(req.body),
        }).substring(0, 500),
        created_at: new Date().toISOString(),
      });
    } catch (err) {
      // Audit failure must NEVER break the app — just log
      console.error('⚠️  Audit log write failed:', err.message);
    }
  });
};

function sanitizeBody(body) {
  if (!body) return {};
  const safe = { ...body };
  delete safe.password;
  delete safe.password_hash;
  delete safe.access_token;
  delete safe.refresh_token;
  return safe;
}

module.exports = { auditLog };
