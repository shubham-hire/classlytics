const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');

// Dashboard stats
router.get('/stats', adminController.getStats);

// User CRUD
router.get('/users', adminController.getUsers);
router.get('/users/:id', adminController.getUserById);
router.post('/users', adminController.createUser);
router.put('/users/:id', adminController.updateUser);
router.delete('/users/:id', adminController.deleteUser);

// Activate / Deactivate
router.patch('/users/:id/status', adminController.toggleUserStatus);

// Bulk import
router.post('/users/bulk', adminController.bulkCreateUsers);

// Helper endpoints for dropdowns
router.get('/classes', adminController.getClasses);
router.get('/students/list', adminController.getStudentsList);

module.exports = router;
