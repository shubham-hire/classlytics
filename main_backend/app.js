require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const teacherRoutes = require('./routes/teacherRoutes');
const classRoutes = require('./routes/classRoutes');
const studentRoutes = require('./routes/studentRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');
const marksRoutes = require('./routes/marksRoutes');
const geoRoutes = require('./routes/geoRoutes');
const aiRoutes = require('./routes/aiRoutes');
const assignmentRoutes = require('./routes/assignmentRoutes');
const behaviorRoutes = require('./routes/behaviorRoutes');
const communicationRoutes = require('./routes/communicationRoutes');
const authRoutes = require('./routes/authRoutes');
const feeRoutes = require('./routes/feeRoutes');
const quizRoutes = require('./routes/quizRoutes');
const chatRoutes = require('./routes/chatRoutes');
const parentRoutes = require('./routes/parentRoutes');
const adminRoutes = require('./routes/adminRoutes');

const departmentAdminRoutes = require('./routes/departmentAdminRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const initDb = require('./config/initDb');
const path = require('path');

const app = express();
const PORT = 3000;

// Security Middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" } // Allow Flutter Web to load assets
}));

// Global Rate Limiter
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // Limit each IP to 1000 requests per window
  message: { error: 'Too many requests from this IP, please try again after 15 minutes' }
});
app.use(globalLimiter);

// Specific limiter for login to prevent brute force
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // Limit each IP to 20 login attempts per window
  message: { error: 'Too many login attempts, please try again after 15 minutes' }
});
app.use('/auth/login', loginLimiter);

// Middleware
app.use(express.json({ limit: '20mb' }));
app.use(express.urlencoded({ extended: true, limit: '20mb' }));

// Serve uploaded files (assignment media)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Manual CORS + Logging Middleware
app.use((req, res, next) => {
  console.log(`[REQUEST] ${req.method} ${req.path} from ${req.headers.origin || 'unknown'}`);
  
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization");

  if (req.method === 'OPTIONS') {
    console.log('  -> Responding to Preflight (OPTIONS)');
    return res.sendStatus(200);
  }
  next();
});

// Routes
app.use('/auth', authRoutes);
app.use('/teacher', teacherRoutes);
app.use('/teacher', classRoutes);
app.use('/class', studentRoutes);
app.use('/attendance', attendanceRoutes);
app.use('/marks', marksRoutes);
app.use('/geo', geoRoutes);
app.use('/ai', aiRoutes);
app.use('/student', behaviorRoutes);
app.use('/assignments', assignmentRoutes);
app.use('/communication', communicationRoutes);
app.use('/fee', feeRoutes);         // Legacy (parent fee status)
app.use('/api/fees', feeRoutes);    // New structured endpoint
app.use('/quizzes', quizRoutes);
app.use('/chat', chatRoutes);
app.use('/parent', parentRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/payment', paymentRoutes);

app.use('/dept-admin', departmentAdminRoutes);
app.use('/api/department-admin', departmentAdminRoutes);
app.use('/api/departments', require('./routes/departmentRoutes'));

// Base route for connectivity check
app.get('/', (req, res) => {
  res.send('Classlytics API is running...');
});

if (require.main === module) {
  app.listen(PORT, '0.0.0.0', async () => {
    const { networkInterfaces } = require('os');
    const nets = networkInterfaces();
    let lanIp = 'unknown';
    for (const iface of Object.values(nets)) {
      for (const net of iface) {
        if (net.family === 'IPv4' && !net.internal) { lanIp = net.address; break; }
      }
      if (lanIp !== 'unknown') break;
    }
    console.log(`Server is running on http://localhost:${PORT}`);
    console.log(`Also accessible on local network at http://${lanIp}:${PORT}`);
    // Initialize Database
    await initDb();
  });
}

module.exports = app;

