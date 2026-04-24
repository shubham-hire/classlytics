const express = require('express');
const router = express.Router();
const classController = require('../controllers/classController');
const { verifyToken, requireRole } = require('../middleware/auth');

router.use(verifyToken);
router.use(requireRole('Teacher', 'Admin'));

// Map GET /teacher/classes to controller
router.get('/classes', classController.getClasses);


// Enroll students in a class
router.post('/enroll', classController.enrollStudents);

module.exports = router;
