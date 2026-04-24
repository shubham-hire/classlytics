const express = require('express');
const router = express.Router();
const feeStructureController = require('../controllers/feeStructureController');
const feeAssignmentController = require('../controllers/feeAssignmentController');
const feeController = require('../controllers/feeController');
const { verifyToken, requireRole } = require('../middleware/auth');

router.use(verifyToken);

// ─── Fee Structure (Admin Only) ──────────────────────────────────────────
router.get('/structure', requireRole('Admin', 'Teacher'), feeStructureController.getAllStructures);
router.get('/structure/:id', requireRole('Admin', 'Teacher'), feeStructureController.getStructureById);
router.post('/structure', requireRole('Admin'), feeStructureController.createStructure);
router.put('/structure/:id', requireRole('Admin'), feeStructureController.updateStructure);
router.delete('/structure/:id', requireRole('Admin'), feeStructureController.deleteStructure);

// ─── Fee Assignments (Admin Only) ────────────────────────────────────────
router.get('/assignments', requireRole('Admin'), feeAssignmentController.getAssignments);
router.get('/assignments/student/:studentId', feeAssignmentController.getStudentAssignments); // Ownership check in controller
router.post('/assignments', requireRole('Admin'), feeAssignmentController.assignFee);
router.post('/assignments/bulk', requireRole('Admin'), feeAssignmentController.bulkAssignByClass);
router.delete('/assignments/:id', requireRole('Admin'), feeAssignmentController.removeAssignment);
router.get('/assignments/:id/payments', requireRole('Admin'), feeAssignmentController.getPaymentHistory);
router.post('/assignments/:id/payment', requireRole('Admin'), feeAssignmentController.recordPayment);

router.get('/reports', requireRole('Admin', 'Teacher'), feeAssignmentController.getFeeReports);
router.get('/insights', requireRole('Admin'), feeAssignmentController.getFeeInsights);

// ─── Fee Status (Student/Parent) ──────────────────────────────────────────
router.get('/:studentId', feeController.getFeeStatus); // Ownership check in controller
router.post('/:studentId', requireRole('Admin'), feeController.setFeeRecord);
router.post('/:studentId/payment', requireRole('Admin'), feeController.recordPayment);

module.exports = router;
