const express = require('express');
const router = express.Router();
const marksController = require('../controllers/marksController');

// Map POST /marks to controller
router.post('/', marksController.addMarks);

// Helper for fetching marks
router.get('/:studentId', marksController.getMarksByStudent);

module.exports = router;
