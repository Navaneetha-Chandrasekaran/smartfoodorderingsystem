const express = require('express');
const router = express.Router();
const cartController = require('../controllers/cartController');

router.post('/cart/add', cartController.addToCart);

router.get('/cart/:user_id', cartController.getCart);

router.delete('/cart/remove/:cart_id', cartController.removeItem);
router.put('/cart/update', cartController.updateQuantity);
router.put('/cart/update-delivery-payment', cartController.updateDeliveryPayment);


module.exports = router;
