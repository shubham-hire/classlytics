const express = require('express');
const router = express.Router();
const teacherController = require('../controllers/teacherController');

// GET /teacher/dashboard?teacherId=<id> — Live stats
router.get('/dashboard', teacherController.getDashboardData);

// GET /teacher/schedule — Timetable
router.get('/schedule', teacherController.getSchedule);

// GET /teacher/profile?teacherId=<id>
router.get('/profile', teacherController.getProfile);

// GET /teacher/class-stats?teacherId=<id>
router.get('/class-stats', teacherController.getClassStats);

module.exports = router;
