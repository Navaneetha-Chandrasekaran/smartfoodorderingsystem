//this code is used to update stock and add availability  
//the get and put method is being used . get used for fectch an order with availability,
// put is used to update stock availability
const express = require('express');
const router = express.Router();
const db = require("../config/db");
const foodController = require('../controllers/foodController');

// Routes
router.get('/getfoods',foodController.getUserMenu);

// Canteen Stock API - Handles GET, PUT, and POST in One Endpoint
router.all("/stocks", (req, res) => {
    const method = req.method; // Get the request method
    const { shop_id, food_id, change, food_items, user_id, pickup_time, payment_method ,total_amount} = req.body;

    if (method === "GET") {
        // Fetch menu with availability
        if (!req.query.shop_id) return res.status(400).json({ error: "shop_id is required!" });

        const sql = `
            SELECT f.id AS food_id, f.image, f.name, f.price,f.description, f.category, 
                   COALESCE(s.availability, 0) AS availability
            FROM food_items f
            LEFT JOIN food_stock s ON f.id = s.food_id AND s.shop_id = ?
        `;
        db.query(sql, [req.query.shop_id], (err, results) => {
            if (err) return res.status(500).json({ error: "Database error" });
            return res.json(results);
            
        });

    } else if (method === "PUT") {
        // Update stock manually (Canteen Staff)
        if (!shop_id || !food_id || change === undefined) {
            return res.status(400).json({ error: "shop_id, food_id, and change are required!" });
        }

        const sql = `
            INSERT INTO food_stock (shop_id, food_id, availability)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE availability = GREATEST(availability + VALUES(availability), 0)
        `;
        db.query(sql, [shop_id, food_id, change], (err, result) => {
            if (err) return res.status(500).json({ error: "Database update error" });
            return res.json({ message: "Stock updated successfully!" });
        });

    } else if (method === "POST") {
        // Place an order (User) and decrease stock
        if (!shop_id || !Array.isArray(food_items) || food_items.length === 0 || !user_id || !pickup_time || !payment_method) {
            return res.status(400).json({ error: "Required fields: shop_id, user_id, pickup_time, payment_method, food_items array!" });
        }

        // Generate OTP
        const otp = Math.floor(1000 + Math.random() * 9000);

        // Step 1: Save Order
        const orderSql = "INSERT INTO canteen_orders (user_id, shop_id, pickup_time, payment_method, total_amount,otp, status) VALUES (?, ?, ?, ?, ?,?,'Pending')";
        db.query(orderSql, [user_id, shop_id, pickup_time, payment_method, otp], (err, orderResult) => {
            if (err) return res.status(500).json({ error: "Error saving order" });

            const orderId = orderResult.insertId;

            // Step 2: Save Ordered Items
            const orderItemsSql = "INSERT INTO canteen_order_items (order_id, food_id, quantity) VALUES ?";
            const orderItemsValues = food_items.map(({ food_id, quantity }) => [orderId, food_id, quantity]);

            db.query(orderItemsSql, [orderItemsValues], (err) => {
                if (err) return res.status(500).json({ error: "Error saving order items" });

                // Step 3: Reduce Stock
                const queries = food_items.map(({ food_id, quantity }) => {
                    return new Promise((resolve, reject) => {
                        db.query(
                            "UPDATE food_stock SET availability = GREATEST(availability - ?, 0) WHERE shop_id = ? AND food_id = ?",
                            [quantity, shop_id, food_id],
                            (err, result) => {
                                if (err) reject(err);
                                else resolve();
                            }
                        );
                    });
                });

                Promise.all(queries)
                    .then(() => res.json({ message: "Order placed successfully!", order_id: orderId, otp }))
                    .catch((err) => res.status(500).json({ error: "Error updating availability" }));
            });
        });

    } else {
        return res.status(405).json({ error: "Method Not Allowed" });
    }
});

module.exports = router;
