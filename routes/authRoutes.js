const express = require("express");
const authController = require("../controllers/authController");
const router = express.Router();
const app=express();
const cors = require('cors');
app.use(cors());
app.use(express.json());

//authcontrollers
router.post('/register/student', authController.registerStudent);
router.post('/register/canteenstaff', authController.registerStaff);
router.post('/verify-otp', authController.verifyOTP);
router.post('/login', authController.loginUser);
router.post('/resetpassword', authController.resetPassword);
router.post('/resendotp', authController.resendOTP);
module.exports = router;
