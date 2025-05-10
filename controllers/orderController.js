// this code is used to place an order, fetch an order and order status using websockets 
const db = require("../config/db");
const jwt = require('jsonwebtoken');
// const { sendNewOrder } = require("../server"); // WebSocket function

const validateToken = (req, res, next) => {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
        return res.status(401).json({ error: "No token provided" });
    }

    try {
        // Verify the token and decode it to extract user information
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded; // Attach the decoded user info to the request object
        next();
    } catch (err) {
        return res.status(403).json({ error: "Invalid or expired token",details:err});
    }
};

exports.placeOrder =[validateToken,(req, res) => {
    const { shop_id, pickup_time, payment_method,total_amount, food_items } = req.body;
    const user_id = req.user.id;
    if (!shop_id || !Array.isArray(food_items) || food_items.length === 0 || !user_id || !pickup_time || !payment_method) {
        return res.status(400).json({ error: "Required fields: shop_id, user_id, pickup_time, payment_method, total_amount,food_items array!" });
    }

    // Generate OTP
    const otp = Math.floor(1000 + Math.random() * 9000);

    // Step 1: Save Order
    const orderSql = "INSERT INTO canteen_orders (user_id, shop_id, pickup_time, payment_method, total_amount ,otp, status) VALUES (?, ?, ?, ?, ?,?,'Pending')";
    db.query(orderSql, [user_id, shop_id, pickup_time, payment_method,total_amount, otp], (err, orderResult) => {
        if (err) 
        return res.status(500).json({ error: "Error saving order", details: err });;

        const orderId = orderResult.insertId;

        // Step 2: Save Ordered Items
        const orderItemsSql = "INSERT INTO canteen_order_items (order_id, food_id, quantity) VALUES ?";
        const orderItemsValues = food_items.map(({ food_id, quantity }) => [orderId, food_id, quantity]);

        db.query(orderItemsSql, [orderItemsValues], (err) => {
            if (err) return res.status(500).json({ error: "Error saving order items",details: err});

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
                .then(() => {
                    // Create Order Object for WebSocket
                    const newOrder = {
                        order_id: orderId,
                        user_id,
                        shop_id,
                        pickup_time,
                        payment_method,
                        total_amount,
                        otp,
                        status: "Pending",
                        items: food_items
                    };

                    // **Send order to canteen staff in real-time**
                    // sendNewOrder(shop_id, newOrder);
                    global.io.to(`canteen_${shop_id}`).emit("new_order", newOrder);


                    res.json({ message: "Order placed successfully!", order_id: orderId, otp });
                })
                .catch(() => res.status(500).json({ error: "Error updating availability" }));
        });
    });
}];

// Fetch an order for canteen staff
exports.getCanteenOrders = (req, res) => {
    const { shop_id } = req.params;

    const sql = `
        SELECT o.id As order_id, o.user_id, o.pickup_time, o.payment_method,o.total_amount,o.otp, o.status,
               oi.food_id, oi.quantity, f.name
        FROM canteen_orders o
        JOIN canteen_order_items oi ON o.id = oi.order_id
        JOIN food_items f ON oi.food_id = f.id
        WHERE o.shop_id = ? AND o.status NOT IN ('Delivered')
        ORDER BY o.id DESC;
    `;

    db.query(sql, [shop_id], (err, results) => {
        if (err) return res.status(500).json({ error: "Error fetching active orders",details:err });
        res.json(results);
    });
};

// fetch an compleetd orders for an caneen satff
exports.getPastOrders = (req, res) => {
    const { shop_id } = req.params; // Get shop_id from URL params
    console.log("Received shop_id:", shop_id);
    const sql = `SELECT o.id , o.user_id, o.pickup_time, o.payment_method,o.total_amount,o.otp, o.status,
      oi.food_id, oi.quantity, f.name
      FROM canteen_orders o
       JOIN canteen_order_items oi ON o.id = oi.order_id
         JOIN food_items f ON oi.food_id = f.id
               WHERE o.shop_id = ? AND o.status ='Delivered'
          ORDER BY o.id DESC`;

    db.query(sql, [shop_id], (err, results) => {
        if (err) return res.status(500).json({ error: "Database error",details:err });
        res.json(results);
    });
};


// order staus update in user page
// In your orderController.js or a separate controller
exports.updateOrderStatus = (req, res) => {
    const { order_id } = req.body;

    // Retrieve the current status and user_id from the database
    const sql = "SELECT status, user_id FROM canteen_orders WHERE id = ?";
    db.query(sql, [order_id], (err, result) => {
        if (err) return res.status(500).json({ error: "Error fetching order status" });

        if (result.length === 0) return res.status(404).json({ error: "Order not found",details :err });

        const currentStatus = result[0].status;
        const user_id = result[0].user_id;  // Get user ID

        // Status sequence
        const statusSequence = ["Pending", "Confirmed", "Preparing", "Ready for Pickup", "Delivered"];
        const currentIndex = statusSequence.indexOf(currentStatus);

        if (currentIndex === -1 || currentIndex === statusSequence.length - 1) {
            return res.status(400).json({ error: "Invalid status or order is already completed" });
        }

        // Move to the next status
        const nextStatus = statusSequence[currentIndex + 1];

        // Update order status in the database
        const updateSql = "UPDATE canteen_orders SET status = ? WHERE id = ?";
        db.query(updateSql, [nextStatus, order_id], (err, result) => {
            if (err) return res.status(500).json({ error: "Error updating order status" });

            // Send real-time update only to the user who placed the order
            io.to(`user_${user_id}`).emit("updateOrderStatus", { order_id, new_status: nextStatus });

            res.json({ message: `Order status updated to ${nextStatus}`, order_id, status: nextStatus });
        });
    });
};


// Verify OTP and mark order as completed
exports.verifyOrderOtp = (req, res) => {
    const { order_id, entered_otp } = req.body;

    if (!order_id || !entered_otp) {
        return res.status(400).json({ error: "Required fields: order_id and entered_otp" });
    }

    const sql = "SELECT otp, user_id FROM canteen_orders WHERE id = ?";
    db.query(sql, [order_id], (err, results) => {
        if (err) return res.status(500).json({ error: "Error fetching order details" });
        if (results.length === 0) return res.status(404).json({ error: "Order not found" });

        const order = results[0];
        if (order.otp == entered_otp) {
            // OTP matches, mark order as verified
            const updateSql = "UPDATE canteen_orders SET status = 'Delivered' WHERE id = ?";
            db.query(updateSql, [order_id], (err, updateResult) => {
                if (err) return res.status(500).json({ error: "Error updating order status after OTP verification",details:err });

                // Optionally, you can send WebSocket update to user
                io.to(`user_${order.user_id}`).emit("orderCompleted", { order_id });

                res.json({ message: "OTP verified successfully! Order is marked as Completed ✅" });
            });
        } else {
            res.status(400).json({ error: "Invalid OTP. Please try again!" });
        }
    });
};


// fetch orders for users
exports.getUserOrders = [validateToken, (req, res) => {
    const user_id = req.user.id; // Get user_id from token

    const sql = `
        SELECT 
            o.id AS order_id,
            o.otp,
            oi.quantity,
            o.total_amount,
            f.name AS food_name,
            f.image AS food_image
        FROM canteen_orders o
        JOIN canteen_order_items oi ON o.id = oi.order_id
        JOIN food_items f ON oi.food_id = f.id
        WHERE o.user_id = ?
        ORDER BY o.id DESC`;

    db.query(sql, [user_id], (err, results) => {
        if (err) return res.status(500).json({ error: "Database error", details: err });
        res.json(results);
    });
}];


exports.getUserOrderHistory = [validateToken, (req, res) => {
    const user_id = req.user.id;

    const sql = `
        SELECT 
            o.id AS order_id,
            o.otp,
            o.pickup_time,
            o.payment_method,
            o.status,
            f.name AS food_name,
            f.image AS food_image,
            oi.quantity
        FROM canteen_orders o
        JOIN canteen_order_items oi ON o.id = oi.order_id
        JOIN food_items f ON oi.food_id = f.id
        WHERE o.user_id = ?
        ORDER BY o.id DESC
    `;

    db.query(sql, [user_id], (err, results) => {
        if (err) {
            console.error("Database error", err);
            return res.status(500).json({ error: "Database error", details: err });
        }

        // Group by order_id
        const orderHistory = {};

        results.forEach(row => {
            if (!orderHistory[row.order_id]) {
                orderHistory[row.order_id] = {
                    order_id: row.order_id,
                    otp: row.otp,
                    pickup_time: row.pickup_time,
                    payment_method: row.payment_method,
                    status: row.status,
                    foods: []
                };
            }
            orderHistory[row.order_id].foods.push({
                name: row.food_name,
                image: row.food_image,
                quantity: row.quantity
            });
        });

        res.json(Object.values(orderHistory));
    });
}];
