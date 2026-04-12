const express = require('express');
const router = express.Router();
const teacherController = require('../controllers/teacherController');

// Map GET /teacher/dashboard to controller
router.get('/dashboard', teacherController.getDashboardData);

module.exports = router;
