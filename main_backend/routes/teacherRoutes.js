const express = require('express');
const router = express.Router();
const teacherController = require('../controllers/teacherController');

// Map GET /teacher/dashboard to controller
router.get('/dashboard', teacherController.getDashboardData);

// Map GET /teacher/schedule to controller
router.get('/schedule', teacherController.getSchedule);

// Map GET /teacher/profile to controller
router.get('/profile', teacherController.getProfile);

module.exports = router;
