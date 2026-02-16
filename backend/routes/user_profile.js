const express = require('express');
const router = express.Router();
const getUserprofile = require('../controller/userprofile');

router.get('/get-profiles', getUserprofile.getUserProfile);


module.exports = router;