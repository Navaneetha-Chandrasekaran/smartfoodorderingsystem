const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
    }
});

const sendOTP = (email, otp) => {
    const mailOptions = {
        from: process.env.EMAIL_USER,
        to: email,
        subject: 'Your OTP for Verification',
        text: ` Dear Customer :
                Your OTP for verification is: ${otp}`
    };
    
   

   
    return transporter.sendMail(mailOptions);
};

module.exports = sendOTP;

