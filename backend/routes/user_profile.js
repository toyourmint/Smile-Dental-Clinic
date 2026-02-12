const express = require('express');
const router = express.Router();
const getUserprofile = require('../controller/getUserprofile');

router.get('/get-profiles', getUserprofile.getUserProfile);


module.exports = router;