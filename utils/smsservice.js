const twilio = require("twilio");
const dotenv = require("dotenv");

dotenv.config();

const client = twilio(process.env.TWILIO_SID, process.env.TWILIO_AUTH_TOKEN);

exports.sendOTP = (phone, message) => {
    client.messages
        .create({
            body: message,
            from: process.env.TWILIO_PHONE,
            to: phone
        })
        .then(() => console.log(` OTP sent to ${phone}`))
        .catch(err => console.error(" Error sending OTP:", err));
};
