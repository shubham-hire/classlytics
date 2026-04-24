const express = require('express');
const router = express.Router();
const teacherController = require('../controllers/teacherController');
const { verifyToken, requireRole } = require('../middleware/auth');

// All teacher routes require a valid JWT and 'Teacher' or 'Admin' role
router.use(verifyToken);
router.use(requireRole('Teacher', 'Admin'));

// GET /teacher/dashboard?teacherId=<id> — Live stats
router.get('/dashboard', teacherController.getDashboardData);

// GET /teacher/schedule — Timetable
router.get('/schedule', teacherController.getSchedule);

// GET /teacher/profile?teacherId=<id>
router.get('/profile', teacherController.getProfile);

// GET /teacher/class-stats?teacherId=<id>
router.get('/class-stats', teacherController.getClassStats);

module.exports = router;
