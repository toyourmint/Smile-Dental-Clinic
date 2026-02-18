const express = require('express');
const router = express.Router();
const queueController = require('../controller/queueController');

router.post('/generate', queueController.generateQueueNo);
router.get('/next', queueController.nextQueueNo);
router.post('/skip', queueController.skipQueueNo);
router.get('/room', queueController.getRoomQueues);
router.get('/all', queueController.getAllQueues);

module.exports = router;