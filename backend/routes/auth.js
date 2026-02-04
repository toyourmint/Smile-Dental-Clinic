const express = require('express');
const router = express.Router();
const authController = require('../controller/authController');

router.post('/register', authController.register);
router.post('/login', authController.login);

router.post('/verify-otp', authController.verifyOtp);
router.post('/resend-otp', authController.resendOtp);
router.post('/set-password', authController.setPassword);

module.exports = router;