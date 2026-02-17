const express = require('express');
const router = express.Router();
const getUserprofile = require('../controller/userprofile');
const verify = require('../middlewares/authMiddleware');

router.get('/getprofiles', verify, getUserprofile.getUserProfile);
router.get('/getallprofiles', getUserprofile.getAllUserProfiles);
router.post('/edit', verify, getUserprofile.editUserProfile);

router.get('/doctor', getUserprofile.getDoctorProfile);


module.exports = router;