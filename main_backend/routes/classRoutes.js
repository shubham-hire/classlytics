const express = require('express');
const router = express.Router();
const classController = require('../controllers/classController');

// Map GET /teacher/classes to controller
router.get('/classes', classController.getClasses);

// Map POST /teacher/classes to controller
router.post('/classes', classController.addClass);

// Enroll students in a class
router.post('/enroll', classController.enrollStudents);

module.exports = router;
