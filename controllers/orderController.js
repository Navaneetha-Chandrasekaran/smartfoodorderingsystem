const db = require("../config/db");
const { sendOTP } = require("../utils/smsservice");

// Generate a 6-digit OTP
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

/*Place an Order (Student)
 * - Students place an order with food items.
 * - A common OTP is generated and sent to both student & admin.
 */
exports.placeOrder = (req, res) => {
    const { student_id, phone_number, items } = req.body;
    const otp = generateOTP();

    // Insert order into `orders` table
    db.query("INSERT INTO orders (student_id, otp, status) VALUES (?, ?, 'Pending')", [student_id, otp], (err, result) => {
        if (err) return res.status(500).json({ message: "Database error", error: err });

        const orderId = result.insertId;
        const orderItems = items.map(item => [orderId, item.food_id, item.quantity, item.price]);

        // Insert multiple order items
        db.query("INSERT INTO order_items (order_id, food_id, quantity, price) VALUES ?", [orderItems], (err) => {
            if (err) return res.status(500).json({ message: "Error adding order items", error: err });

            // Send OTP to both student & admin
            sendOTP(phone_number, `Your order OTP: ${otp}`);
            sendOTP(process.env.ADMIN_PHONE, `New Order OTP: ${otp}`);

            res.status(200).json({ message: "Order placed successfully!", order_id: orderId, otp });
        });
    });
};

/**
 *  Update Order Status (Admin)
 *  Admin can update order status to "Preparing", "Ready for Pickup", etc.
 */
exports.updateOrderStatus = (req, res) => {
    const { orderId } = req.params;
    const { status } = req.body;

    const allowedStatuses = ["Pending", "Preparing", "Ready for Pickup", "Completed"];
    if (!allowedStatuses.includes(status)) return res.status(400).json({ message: "Invalid order status!" });

    db.query("UPDATE orders SET status = ? WHERE id = ?", [status, orderId], (err, result) => {
        if (err) return res.status(500).json({ message: "Database error", error: err });
        res.status(200).json({ message: "Order status updated successfully!" });
    });
};
