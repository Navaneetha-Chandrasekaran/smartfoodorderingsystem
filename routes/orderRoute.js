const express = require("express");
const { placeOrder, updateOrderStatus } = require("../controllers/orderController");
const { verifyToken } = require("../middleware/authMiddleware");

const router = express.Router();

// 🛒 Place an Order (Student)
router.post("/place", verifyToken, placeOrder);

// 🔄 Update Order Status (Admin)
router.put("/update/:orderId", verifyToken, updateOrderStatus);

module.exports = router;
