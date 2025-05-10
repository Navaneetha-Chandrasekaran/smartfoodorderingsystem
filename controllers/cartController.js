const db = require("../config/db");
const jwt = require('jsonwebtoken');

// Middleware to validate JWT and extract user info
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

// Add item to cart
exports.addToCart = [validateToken, (req, res) => {
    const { shop_id, food_id } = req.body;
    const user_id = req.user.id; // Get user_id from the decoded token

    if (!shop_id || !food_id) {
        return res.status(400).json({ error: "All fields are required!" });
    }

    const sql = "INSERT INTO cart (user_id, shop_id, food_id) VALUES (?, ?, ?)";
    db.query(sql, [user_id, shop_id, food_id], (err, result) => {
        if (err) return res.status(500).json({ error: "Database error",details:err });
        res.json({ message: "Item added to cart!" });
    });
}];

// Fetch cart items
exports.getCartItems = [validateToken, (req, res) => {
    const user_id = req.user.id; // Get user_id from the decoded token

    if (!user_id) return res.status(400).json({ error: "User ID required!" });

    const sql = `
        SELECT c.id AS cart_id, f.id AS food_id, f.name, f.image, f.price, f.category
        FROM cart c
        JOIN food_items f ON c.food_id = f.id
        WHERE c.user_id = ?
    `;

    db.query(sql, [user_id], (err, results) => {
        if (err) return res.status(500).json({ error: "Database error" });
        res.json(results);
    });
}];

// Remove item from cart
exports.removeCartItem = [validateToken, (req, res) => {
    const { cart_id } = req.params;
    const user_id = req.user.id; // Get user_id from the decoded token

    if (!cart_id) {
        return res.status(400).json({ error: "Cart ID is required!" });
    }

    const sql = "DELETE FROM cart WHERE id = ? AND user_id = ?";
    db.query(sql, [cart_id, user_id], (err, result) => {
        if (err) {
            console.error("Database Error:", err);
            return res.status(500).json({ error: "Database error, please try again later" });
        }

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: "Cart item not found!" });
        }

        res.json({ message: "Item removed from cart!" });
    });
}];

// Clear cart after placing order
exports.clearCart = [validateToken, (req, res) => {
    const user_id = req.user.id; // Get user_id from the decoded token

    const sql = "DELETE FROM cart WHERE user_id = ?";
    db.query(sql, [user_id], (err, result) => {
        if (err) return res.status(500).json({ error: "Database error" });
        res.json({ message: "Cart cleared!" });
    });
}];



// const db = require("../config/db");

// // Add item to cart
// exports.addToCart = (req, res) => {
//     const { user_id, shop_id, food_id } = req.body;

//     if (!user_id || !shop_id || !food_id) {
//         return res.status(400).json({ error: "All fields are required!" });
//     }

//     const sql = "INSERT INTO cart (user_id, shop_id, food_id) VALUES (?, ?, ?)";
//     db.query(sql, [user_id, shop_id, food_id], (err, result) => {
//         if (err) return res.status(500).json({ error: "Database error" });
//         res.json({ message: "Item added to cart!" });
//     });
// };

// // Fetch cart items
// exports.getCartItems = (req, res) => {
//     const { user_id } = req.params;

//     if (!user_id) return res.status(400).json({ error: "User ID required!" });

//     const sql = `
//         SELECT c.id AS cart_id, f.id AS food_id, f.name, f.image, f.price, f.category
//         FROM cart c
//         JOIN food_items f ON c.food_id = f.id
//         WHERE c.user_id = ?
//     `;

//     db.query(sql, [user_id], (err, results) => {
//         if (err) return res.status(500).json({ error: "Database error" });
//         res.json(results);
//     });
// };

// // Remove item from cart
// exports.removeCartItem = (req, res) => {
//     const { cart_id } = req.params;

//     if (!cart_id) {
//         return res.status(400).json({ error: "Cart ID is required!" });
//     }

//     const sql = "DELETE FROM cart WHERE id = ?";
//     db.query(sql, [cart_id], (err, result) => {
//         if (err) {
//             console.error("Database Error:", err);
//             return res.status(500).json({ error: "Database error, please try again later" });
//         }

//         if (result.affectedRows === 0) {
//             return res.status(404).json({ error: "Cart item not found!" });
//         }

//         res.json({ message: "Item removed from cart!" });
//     });
// };

// // Clear cart after placing order
// exports.clearCart = (req, res) => {
//     const { user_id } = req.params;

//     const sql = "DELETE FROM cart WHERE user_id = ?";
//     db.query(sql, [user_id], (err, result) => {
//         if (err) return res.status(500).json({ error: "Database error" });
//         res.json({ message: "Cart cleared!" });
//     });
// };
