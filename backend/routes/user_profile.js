const express = require('express');
const router = express.Router();
const getUserprofile = require('../controller/userprofile');
const verify = require('../middlewares/authMiddleware');

router.get('/getprofiles', verify, getUserprofile.getUserProfile);
router.get('/getallprofiles', verify, getUserprofile.getAllUserProfiles);
router.put('/editprofile/:id', verify, getUserprofile.editUserProfile);

router.get('/doctor', verify, getUserprofile.getDoctorProfile);


module.exports = router;