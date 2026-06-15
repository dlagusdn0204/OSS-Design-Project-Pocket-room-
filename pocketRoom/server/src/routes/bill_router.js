
const express = require('express');
const { requireAuth } = require('../middleware/auth');
const billController = require('../controllers/bill_controller');

const router = express.Router();

router.get('/:id/cards', requireAuth, billController.getCards);
router.put('/:id/cards/contract', requireAuth, billController.saveContract);
router.post(
  '/:id/cards/electricity/refresh',
  requireAuth,
  billController.refreshElectricity
);
router.post(
  '/:id/cards/cityGas/refresh',
  requireAuth,
  billController.refreshCityGas
);

module.exports = router;
