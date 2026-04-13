require('dotenv').config();
const express = require('express');
const cors = require('cors');
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
const initDb = require('./config/initDb');

const app = express();
const PORT = 3000;

// Middleware
app.use(express.json());

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

// Base route for connectivity check
app.get('/', (req, res) => {
  res.send('Classlytics Teacher API is running...');
});

app.listen(PORT, '0.0.0.0', async () => {
  console.log(`Server is running on http://localhost:${PORT}`);
  console.log(`Also accessible on local network at http://192.168.1.4:${PORT}`);
  // Initialize Database
  await initDb();
});
