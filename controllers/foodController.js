//this code is used to fetch menu ,availability with shop id and category for useres
const db = require("../config/db");

exports.getUserMenu = (req, res) => {
    const { shop_id, category } = req.query;

    if (!shop_id || !category) {
        return res.status(400).json({ error: "shop_id and category are required!" });
    }

    const sql = `
        SELECT f.id AS food_id, f.name, f.image, f.price, f.category, 
               COALESCE(s.availability, 0) AS availability
        FROM food_items f
        LEFT JOIN food_stock s ON f.id = s.food_id AND s.shop_id = ?
        WHERE f.category = ?
    `;

    db.query(sql, [shop_id, category], (err, results) => {
        if (err) return res.status(500).json({ error: "Database error" });
        res.json(results);
    });
};
