const { haversineDistance } = require('../utils/haversine');
const env = require('../config/env');

/**
 * Check if student is within allowed range of teacher
 * @returns {{ isValid: boolean, distance: number }}
 */
function verifyLocation(teacherLat, teacherLng, studentLat, studentLng) {
  const distance = haversineDistance(teacherLat, teacherLng, studentLat, studentLng);
  
  return {
    isValid: distance <= env.MAX_DISTANCE,
    distance: Math.round(distance * 100) / 100, // round to 2 decimals
  };
}

module.exports = { verifyLocation };
