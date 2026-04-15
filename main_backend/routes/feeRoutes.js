const express = require('express');
const router = express.Router();
const feeController = require('../controllers/feeController');

// GET /fee/:studentId — Get fee status
router.get('/:studentId', feeController.getFeeStatus);

// POST /fee/:studentId — Create/update fee record
router.post('/:studentId', feeController.setFeeRecord);

// POST /fee/:studentId/payment — Record a payment
router.post('/:studentId/payment', feeController.recordPayment);

module.exports = router;
