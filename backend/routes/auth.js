const express = require('express');
const router = express.Router();
const authController = require('../controller/authController');
const verify = require('../middlewares/authMiddleware');


router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/admin', authController.loginAdmin);
router.post('/addUser', verify, authController.addUserByAdmin);
router.post('/logout', verify, authController.logout);

router.post('/forgot-password', authController.requestPasswordReset);
router.post('/verify-otp', authController.verifyOtp);
router.post('/resend-otp', authController.resendOtp);
router.post('/set-password', authController.setPassword);

module.exports = router;