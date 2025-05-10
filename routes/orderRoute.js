const express = require("express");
const router = express.Router();
const db = require("../config/db");
const orderController=require('../controllers/orderController');

router.get("/getorder/:shop_id",orderController.getCanteenOrders);
router.post("/placeorder",orderController.placeOrder);
router.get("/pastorder/:shop_id",orderController.getPastOrders);
router.put("/updateorder",orderController.updateOrderStatus);
router.post("/verifyotp",orderController.verifyOrderOtp);
router.get("/fetchorders",orderController.getUserOrders);
router.get("/orderhistory",orderController.getUserOrderHistory);
module.exports = router;