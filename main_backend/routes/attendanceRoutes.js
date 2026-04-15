const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');

// POST /attendance/batch — Bulk attendance for a class
router.post('/batch', attendanceController.markBatchAttendance);

// POST /attendance — Mark single student attendance
router.post('/', attendanceController.markAttendance);

// GET /attendance/class/:classId — Class-level summary
router.get('/class/:classId', attendanceController.getClassAttendanceSummary);

// GET /attendance/:studentId — Individual student attendance
router.get('/:studentId', attendanceController.getAttendanceByStudent);

module.exports = router;
