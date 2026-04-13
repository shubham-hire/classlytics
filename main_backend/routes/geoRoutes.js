const express = require('express');
const router = express.Router();
const geoController = require('../controllers/geoController');

router.get('/states', geoController.getStates);
router.get('/cities/:stateCode', geoController.getCities);

module.exports = router;
