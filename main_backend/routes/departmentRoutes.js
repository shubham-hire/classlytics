const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/departmentController');
const { verifyToken, checkRole } = require('../middleware/auth');

// Public/Internal fetch (requires login)
router.get('/', verifyToken, ctrl.getAllDepartments);
router.get('/:id', verifyToken, ctrl.getDepartmentById);

// Administrative actions (ADMIN or Admin)
router.post('/', verifyToken, checkRole('ADMIN', 'Admin'), ctrl.createDepartment);
router.delete('/:id', verifyToken, checkRole('ADMIN', 'Admin'), ctrl.deleteDepartment);

module.exports = router;
