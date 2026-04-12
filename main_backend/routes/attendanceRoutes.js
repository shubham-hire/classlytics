const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');

// Map POST /attendance to record
router.post('/', attendanceController.markAttendance);

// Map GET /attendance/:studentId to fetch history
router.get('/:studentId', attendanceController.getAttendanceByStudent);

module.exports = router;
