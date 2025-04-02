const db = require("../config/db");
const upload = require("../config/multerconfig");
const fs = require("fs");
const path = require("path");

// Admin Login
exports.adminLogin = (req, res) => {
    const { id, password } = req.body;
    if (id == "admin@2025" && password === "admin@2025") {
        res.json({ message: "Admin login successful" });
    } else {
        res.status(401).json({ error: "Invalid credentials" });
    }
};

// Add Food Item
exports.addFoodItem = (req, res) => {
    upload.single("image")(req, res, (err) => {
        if (err) return res.status(400).json({ error: err.message });

        const { shop_id, name, description, price, category,type } = req.body;
        const image = req.file ? req.file.filename : null;

        if (!shop_id || !image || !name || !description || !price || !category) {
            return res.status(400).json({ error: "All fields are required!" });
        }

        const sql = "INSERT INTO food_items (shop_id, image, name, description, price,category,type) VALUES (?, ?, ?, ?, ?, ?,?)";
        db.query(sql, [shop_id, image, name, description, price, category,type], (err, result) => {
            if (err) return res.status(500).json({ error: "Database error" });
            res.json({ message: "Food item added successfully!", image_url: `http://localhost:5000/uploads/${image}` });
        });
    });
};

exports.updateFoodItem = (req, res) => {
    const { id } = req.params;  // Food item ID
    const { shop_id, name, description, price, category,type } = req.body; // Shop ID from request
    const image = req.file ? req.file.filename : null; // Get uploaded file if exists

    if (!shop_id) {
        return res.status(400).json({ error: "shop_id is required!" });
    }

    // Fetch existing food item for the given shop
    db.query("SELECT * FROM food_items WHERE id = ? AND shop_id = ?", [id, shop_id], (err, results) => {
        if (err) return res.status(500).json({ error: "Database error" });
        if (results.length === 0) return res.status(404).json({ error: "Food item not found in this shop!" });

        const existingFood = results[0];
        const updatedImage = image || existingFood.image; // Keep old image if no new one

        const sql = "UPDATE food_items SET image=?, name=?, description=?, price=?, category=?, type=? WHERE id=? AND shop_id=?";
        db.query(sql, 
            [updatedImage, name || existingFood.name, description || existingFood.description, price || existingFood.price, category || existingFood.category,type ||
                existingFood.type, id, shop_id], 
            (err, result) => {
                if (err) return res.status(500).json({ error: "Database error" });

                // Delete old image if a new one is uploaded
                if (image && existingFood.image) {
                    const oldImagePath = path.join(__dirname, "../uploads", existingFood.image);
                    fs.unlink(oldImagePath, (err) => {
                        if (err) console.log("Error deleting old image:", err);
                    });
                }

                res.json({
                    message: "Food item updated successfully!",
                    image_url: `http://localhost:5000/uploads/${updatedImage}`
                });
            }
        );
    });
}

// Delete Food Item
exports.deleteFoodItem = (req, res) => {
    const { id } = req.params;

    db.query("SELECT * FROM food_items WHERE id = ?", [id], (err, results) => {
        if (err) return res.status(500).json({ error: "Database error" });
        if (results.length === 0) return res.status(404).json({ error: "Food item not found!" });

        const imagePath = path.join(__dirname, "../uploads", results[0].image);
        fs.unlink(imagePath, (err) => {
            if (err) console.log("Image deletion error:", err);

            db.query("DELETE FROM food_items WHERE id = ?", [id], (err, result) => {
                if (err) return res.status(500).json({ error: "Database error" });
                res.json({ message: "Food item deleted successfully!" });
            });
        });
    });
};

// Fetch Food Items by Category and Shop
exports.getFoodItems = (req, res) => {
    const { shop_id, category } = req.query;
    let query = "SELECT * FROM food_items WHERE 1";
    let values = [];
    
    if (shop_id) {
        query += " AND shop_id = ?";
        values.push(parseInt(shop_id));
    }
    if (category) {
        query += " AND category = ?";
        values.push(category);
    }

    db.query(query, values, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
};



