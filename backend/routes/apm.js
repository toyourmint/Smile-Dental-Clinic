const express = require('express');
const router = express.Router();
const apmController = require('../controller/apmController');

router.post('/bookAppointmentByUser', apmController.bookAppointmentByUser);
router.post('/bookAppointmentByAdmin', apmController.bookAppointmentByAdmin);
router.get('/availableSlots', apmController.getAvailableSlots);

module.exports = router;