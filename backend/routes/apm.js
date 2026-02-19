const express = require('express');
const router = express.Router();
const apmController = require('../controller/apmController');

const verify = require('../middlewares/authMiddleware');

router.post('/apmUser', verify, apmController.bookAppointmentByUser);
router.post('/apmAdmin', apmController.bookAppointmentByAdmin);
router.get('/slots', apmController.getAvailableSlots);

router.get('/all', apmController.getAllAppointments);
router.put('/cancel/:id', apmController.cancelAppointment);

module.exports = router;