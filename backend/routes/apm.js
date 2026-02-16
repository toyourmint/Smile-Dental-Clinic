const express = require('express');
const router = express.Router();
const apmController = require('../controller/apmController');

const verify = require('../middleware/authMiddleware');

router.post('/bookAppointmentByUser', verify, apmController.bookAppointmentByUser);
router.post('/bookAppointmentByAdmin', verify, apmController.bookAppointmentByAdmin);
router.get('/availableSlots', apmController.getAvailableSlots);

module.exports = router;