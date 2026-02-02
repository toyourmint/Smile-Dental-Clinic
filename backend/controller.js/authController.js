// ##test authController.js##
const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

exports.register = async (req, res) => {
    // Registration logic here
    res.status(201).json({ message: 'User registered successfully' });
}
exports.login = async (req, res) => {
    // Login logic here
    res.status(200).json({ message: 'User logged in successfully' });
}

module.exports = router;