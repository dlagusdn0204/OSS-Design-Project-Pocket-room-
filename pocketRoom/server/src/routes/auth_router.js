
const express = require('express');
const authController = require('../controllers/auth_controller');

const router = express.Router();

router.post('/signup', authController.signup);
router.get('/check-id', authController.checkId);
router.post('/login', authController.login);
router.post('/refresh', authController.refresh);
router.post('/find-id', authController.findId);
router.post('/reset-password', authController.resetPassword);

module.exports = router;
