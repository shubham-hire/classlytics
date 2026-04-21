const express = require('express');
const router = express.Router();
const feeStructureController = require('../controllers/feeStructureController');
const feeAssignmentController = require('../controllers/feeAssignmentController');
const feeController = require('../controllers/feeController');

// ─── Fee Structure (Admin) ─────────────────────────────────────────────────
router.get('/structure', feeStructureController.getAllStructures);
router.get('/structure/:id', feeStructureController.getStructureById);
router.post('/structure', feeStructureController.createStructure);
router.put('/structure/:id', feeStructureController.updateStructure);
router.delete('/structure/:id', feeStructureController.deleteStructure);

// ─── Fee Assignments (Admin) ───────────────────────────────────────────────
router.get('/assignments', feeAssignmentController.getAssignments);
router.get('/assignments/student/:studentId', feeAssignmentController.getStudentAssignments);
router.post('/assignments', feeAssignmentController.assignFee);
router.post('/assignments/bulk', feeAssignmentController.bulkAssignByClass);
router.delete('/assignments/:id', feeAssignmentController.removeAssignment);
router.get('/assignments/:id/payments', feeAssignmentController.getPaymentHistory);
router.post('/assignments/:id/payment', feeAssignmentController.recordPayment);

router.get('/reports', feeAssignmentController.getFeeReports);
router.get('/insights', feeAssignmentController.getFeeInsights);

// ─── Fee Status (Student/Parent — legacy) ─────────────────────────────────
router.get('/:studentId', feeController.getFeeStatus);
router.post('/:studentId', feeController.setFeeRecord);
router.post('/:studentId/payment', feeController.recordPayment);

module.exports = router;
