require('dotenv').config();

const env = {
  PORT: process.env.PORT || 3000,
  NODE_ENV: process.env.NODE_ENV || 'development',
  JWT_SECRET: process.env.JWT_SECRET || 'default-secret-change-me',
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '7d',
  QR_ROTATION_INTERVAL: parseInt(process.env.QR_ROTATION_INTERVAL_SECONDS) || 30,
  QR_SESSION_SECRET: process.env.QR_SESSION_SECRET || 'default-qr-secret',
  MAX_DISTANCE: parseInt(process.env.MAX_CHECKIN_DISTANCE_METERS) || 50,
};

module.exports = env;
