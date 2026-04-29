const express = require('express');
const router = express.Router();
const studentController = require('../controllers/studentController');
const { verifyToken, requireRole } = require('../middleware/auth');

// Protected for students
router.use(verifyToken);
// We might allow Parent or Student to view fees
router.use(requireRole('Student', 'Parent', 'Admin'));

router.get('/my-fees', studentController.getMyFees);

module.exports = router;
