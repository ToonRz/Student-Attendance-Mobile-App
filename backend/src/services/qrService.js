const crypto = require('crypto');
const env = require('../config/env');

/**
 * Generate a QR token for a given session secret and time bucket
 * Token changes every QR_ROTATION_INTERVAL seconds
 */
function generateQrToken(sessionSecret, timestamp = null) {
  const now = timestamp || Math.floor(Date.now() / 1000);
  const bucket = Math.floor(now / env.QR_ROTATION_INTERVAL);
  
  const hmac = crypto.createHmac('sha256', env.QR_SESSION_SECRET);
  hmac.update(`${sessionSecret}:${bucket}`);
  return hmac.digest('hex').substring(0, 16); // 16 char token
}

/**
 * Validate a QR token (check current and previous bucket for grace period)
 */
function validateQrToken(sessionSecret, token) {
  const now = Math.floor(Date.now() / 1000);
  
  // Check current bucket
  const currentToken = generateQrToken(sessionSecret, now);
  if (currentToken === token) return true;

  // Check previous bucket (grace period for scanning delay)
  const prevBucket = now - env.QR_ROTATION_INTERVAL;
  const prevToken = generateQrToken(sessionSecret, prevBucket);
  if (prevToken === token) return true;

  return false;
}

/**
 * Generate the QR data payload
 */
function generateQrData(sessionId, sessionSecret) {
  const token = generateQrToken(sessionSecret);
  const expiresAt = Math.floor(Date.now() / 1000) + env.QR_ROTATION_INTERVAL;
  
  return {
    sessionId,
    token,
    expiresAt,
    rotationInterval: env.QR_ROTATION_INTERVAL,
  };
}

module.exports = { generateQrToken, validateQrToken, generateQrData };
