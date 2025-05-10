const Shop = require('../models/shop');
const db = require("../config/db");
exports.createShop = (req, res) => {
    const { name } = req.body;

    if (!name) {
        return res.status(400).json({ message: "Shop name is required" });
    }

    Shop.createShop(name, (err, result) => {
        if (err) {
            return res.status(500).json({ message: "Error adding shop", error: err });
        }
        res.status(201).json({ message: "Shop added successfully", shop_id: result.insertId });
    });
};

exports.getShops = (req, res) => {
    Shop.getAllShops((err, results) => {
        if (err) {
            return res.status(500).json({ message: "Error fetching shops", error: err });
        }
        res.status(200).json({ shops: results });
    });
};


// udate shop status open or close
exports.updateShopStatus = (req, res) => {
    const { shop_id } = req.params;
    const { status } = req.body;

    if (!['Open', 'Closed'].includes(status)) {
        return res.status(400).json({ error: "Status must be 'Open' or 'Closed'" });
    }

    const sql = "UPDATE shops SET status = ? WHERE id = ?";
    db.query(sql, [status, shop_id], (err, result) => {
        if (err) return res.status(500).json({ error: "Database error", details: err });

        // Emit WebSocket event to update status in real-time
        io.to(`canteen_${shop_id}`).emit("shop_status_update", { shop_id, status });

        res.json({ message: "Shop status updated", shop_id, status });
    });
};
