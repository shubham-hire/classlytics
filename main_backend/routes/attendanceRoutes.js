const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');
const { verifyToken, requireRole } = require('../middleware/auth');

router.use(verifyToken);

// Marking attendance is restricted to staff
router.post('/batch', requireRole('Teacher', 'Admin', 'DEPARTMENT_ADMIN'), attendanceController.markBatchAttendance);
router.post('/', requireRole('Teacher', 'Admin', 'DEPARTMENT_ADMIN'), attendanceController.markAttendance);

// Class summary is restricted to staff
router.get('/class/:classId', requireRole('Teacher', 'Admin', 'DEPARTMENT_ADMIN'), attendanceController.getClassAttendanceSummary);

// Individual student history can be viewed by staff OR the student themselves (checked in controller)
router.get('/:studentId', attendanceController.getAttendanceByStudent);

module.exports = router;
