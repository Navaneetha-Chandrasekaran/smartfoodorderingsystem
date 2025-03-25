const express = require('express');
const router = express.Router();
const foodController = require('../controllers/foodController');

// Routes
router.post('/add-food', foodController.addFood);
router.put('/update-food/:id', foodController.updateFood);
router.delete('/delete-food/:id', foodController.deleteFood);
router.get('/shop/:shop_id', foodController.getFoodByShop);

module.exports = router;




// const express = require("express");
// const { addFood, getAllFood, updateFood, deleteFood } = require("../controllers/foodController");
// const { verifyToken, isAdmin } = require("../middleware/authMiddleware");
// const router = express.Router();

// //  Add a food item (Only Admins)

// router.post("/", verifyToken, isAdmin, addFood);

// // Get all food items (Students & Admins)
// router.get("/", getAllFood);

// // Update a food item (Only Admins)
// router.put("/:id", verifyToken, isAdmin, updateFood);

// // Delete a food item (Only Admins)
// router.delete("/:id", verifyToken, isAdmin, deleteFood);

// module.exports = router;
