
const express = require('express');
const { requireAuth } = require('../middleware/auth');
const roomController = require('../controllers/room_controller');

const router = express.Router();

router.get('/', requireAuth, roomController.list);
router.post('/', requireAuth, roomController.create);

module.exports = router;
