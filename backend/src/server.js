const env = require('./config/env');
const app = require('./app');

const PORT = env.PORT;

app.listen(PORT, () => {
  console.log(`
╔══════════════════════════════════════════════╗
║   📚 Student Attendance API                  ║
║   🚀 Running on http://localhost:${PORT}        ║
║   📡 Environment: ${env.NODE_ENV.padEnd(24)}║
╚══════════════════════════════════════════════╝
  `);
});
