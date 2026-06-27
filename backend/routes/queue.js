const express = require('express');
const router = express.Router();
const queueController = require('../controller/queueController');
const verify = require('../middlewares/authMiddleware');

router.post('/generate', verify, queueController.generateQueueNo);
router.get('/next', verify, queueController.nextQueueNo);
router.post('/skip', verify, queueController.skipQueueNo);
router.get('/room', verify, queueController.getRoomQueues);
router.get('/all', verify, queueController.getAllQueues);
router.get('/my/:user_id', verify, queueController.getMyQueue);

module.exports = router;