const express = require('express');
const router = express.Router();
const getUserprofile = require('../controller/userprofile');

router.get('/getprofiles', getUserprofile.getUserProfile);
router.get('/getallprofiles', getUserprofile.getAllUserProfiles);


module.exports = router;