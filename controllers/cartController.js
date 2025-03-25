const db = require('../config/db');

exports.addToCart = (req, res) => {
    const { user_id, food_id, quantity, extra_items } = req.body;

    if (!user_id || !food_id || !quantity) {
        return res.status(400).json({ error: 'All fields are required' });
    }

    const sql = `
        INSERT INTO cart (user_id, food_id, quantity, extra_items)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE quantity = quantity + ?;
    `;

    db.query(sql, [user_id, food_id, quantity, JSON.stringify(extra_items), quantity], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Item added to cart successfully' });
    });
};
exports.getCart = (req, res) => {
    const { user_id } = req.params;

    const sql = `
        SELECT c.id, f.name AS food_name, c.quantity, c.extra_items, f.price 
        FROM cart c
        JOIN food_items f ON c.food_id = f.id
        WHERE c.user_id = ?;
    `;

    db.query(sql, [user_id], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
};
exports.updateQuantity = (req, res) => {
    const { cart_id, quantity } = req.body;

    if (!cart_id || quantity < 1) {
        return res.status(400).json({ error: 'Invalid quantity' });
    }

    const sql = `UPDATE cart SET quantity = ? WHERE id = ?`;

    db.query(sql, [quantity, cart_id], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Quantity updated successfully' });
    });
};
exports.removeItem = (req, res) => {
    const { cart_id } = req.params;

    const sql = `DELETE FROM cart WHERE id = ?`;

    db.query(sql, [cart_id], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Item removed from cart' });
    });
};
exports.updateDeliveryPayment = (req, res) => {
    const { user_id, delivery_time, payment_method } = req.body;

    if (!user_id || !delivery_time || !payment_method) {
        return res.status(400).json({ error: 'All fields are required' });
    }

    const sql = `UPDATE cart SET delivery_time = ?, payment_method = ? WHERE user_id = ?`;

    db.query(sql, [delivery_time, payment_method, user_id], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Delivery time & payment method updated' });
    });
};
const generateOTP = () => Math.floor(100000 + Math.random() * 900000); // 6-digit OTP

exports.checkout = (req, res) => {
    const { user_id } = req.body;

    if (!user_id) return res.status(400).json({ error: 'User ID is required' });

    // Generate OTP
    const otp = generateOTP();

    // Fetch cart details
    const sql = `SELECT * FROM cart WHERE user_id = ?`;

    db.query(sql, [user_id], (err, cartItems) => {
        if (err) return res.status(500).json({ error: err.message });

        if (cartItems.length === 0) return res.status(400).json({ error: 'Cart is empty' });

        // Store order in orders table
        const orderSql = `INSERT INTO orders (user_id, items, delivery_time, payment_method, otp) VALUES (?, ?, ?, ?, ?)`;

        db.query(
            orderSql,
            [user_id, JSON.stringify(cartItems), cartItems[0].delivery_time, cartItems[0].payment_method, otp],
            (err, result) => {
                if (err) return res.status(500).json({ error: err.message });

                // Clear cart after checkout
                db.query(`DELETE FROM cart WHERE user_id = ?`, [user_id]);

                res.json({
                    message: 'Order placed successfully',
                    otp,
                    order_id: result.insertId
                });
            }
        );
    });
};





// const db = require("../config/db");

// // Add to Cart
// exports.addToCart = (req, res) => {
//     const { user_id, food_id, quantity } = req.body;

//     db.query("SELECT * FROM cart WHERE user_id = ? AND food_id = ?", [user_id, food_id], (err, results) => {
//         if (err) return res.status(500).json({ error: "Database error" });

//         if (results.length > 0) {
//             db.query("UPDATE cart SET quantity = quantity + ? WHERE user_id = ? AND food_id = ?", [quantity, user_id, food_id], (err) => {
//                 if (err) return res.status(500).json({ error: "Database error" });
//                 res.json({ message: "Cart updated successfully" });
//             });
//         } else {
//             db.query("INSERT INTO cart (user_id, food_id, quantity) VALUES (?, ?, ?)", [user_id, food_id, quantity], (err) => {
//                 if (err) return res.status(500).json({ error: "Database error" });
//                 res.json({ message: "Item added to cart" });
//             });
//         }
//     });
// };

// //  Get Cart Items
// exports.getCart = (req, res) => {
//     const user_id = req.params.user_id;

//     db.query(
//         `SELECT cart.id, cart.food_id, food.name, food.price, cart.quantity, (food.price * cart.quantity) AS total_price 
//          FROM cart JOIN food ON cart.food_id = food.id WHERE cart.user_id = ?`,
//         [user_id],
//         (err, results) => {
//             if (err) return res.status(500).json({ error: "Database error" });
//             res.json(results);
//         }
//     );
// };

// // Update Cart (Increase/Decrease Quantity)
// exports.updateCart = (req, res) => {
//     const { cart_id, quantity } = req.body;

//     if (quantity <= 0) {
//         db.query("DELETE FROM cart WHERE id = ?", [cart_id], (err) => {
//             if (err) return res.status(500).json({ error: "Database error" });
//             res.json({ message: "Item removed from cart" });
//         });
//     } else {
//         db.query("UPDATE cart SET quantity = ? WHERE id = ?", [quantity, cart_id], (err) => {
//             if (err) return res.status(500).json({ error: "Database error" });
//             res.json({ message: "Cart updated successfully" });
//         });
//     }
// };

// //  Clear Cart After Order
// exports.clearCart = (req, res) => {
//     const user_id = req.params.user_id;

//     db.query("DELETE FROM cart WHERE user_id = ?", [user_id], (err) => {
//         if (err) return res.status(500).json({ error: "Database error" });
//         res.json({ message: "Cart cleared" });
//     });
// };
