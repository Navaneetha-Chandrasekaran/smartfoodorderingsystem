const express = require("express");
const router = express.Router();
const adminController = require("../controllers/adminController");
const upload = require("../config/multerconfig");

// Admin Login
router.post("/login", adminController.adminLogin);

// Food Management
// router.post("/addFood", upload.single('image'), adminController.addFoodItem);
router.post("/addfood", adminController.addFoodItem);
router.put("/updateFood/:id", upload.single('image'), adminController.updateFoodItem);
router.delete("/deleteFood/:id", adminController.deleteFoodItem);

// Fetch Food Items by Category and Shop

router.get('/foodItems', adminController.getFoodItems);

module.exports = router;
