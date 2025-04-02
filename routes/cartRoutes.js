const express = require('express');
const router = express.Router();
const cartController = require('../controllers/cartController');

router.post("/add", cartController.addToCart);
router.get("/view/:user_id", cartController.getCartItems);
router.delete("/remove/:cart_id", cartController.removeCartItem);
router.delete("/clear/:user_id", cartController.clearCart);
module.exports = router;
