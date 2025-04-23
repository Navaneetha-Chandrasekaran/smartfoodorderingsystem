//this code is used to fetch menu ,availability with shop id and category for useres
const db = require("../config/db");

exports.getUserMenu = (req, res) => {
    const {shop_id,category,type} = req.query;
    console.log("SHOP_ID:", shop_id);
    console.log("CATEGORY:", category);
    console.log("TYPE:", type);

    if (!shop_id || !category) {
        return res.status(400).json({ error: "shop_id and category are required!" });
    }

    const sql = `
        SELECT  food_id, f.name, f.image, f.price, f.category, f.description,
               COALESCE(s.availability, 0) AS availability
        FROM food_items f
        LEFT JOIN food_stock s ON food_id = s.food_id AND s.shop_id = ?
        WHERE f.category = ? AND f.type=?
    `;
    const formatted = db.format(sql, [shop_id, category, type]);
    console.log("Executing SQL:", formatted);

    db.query(sql, [shop_id, category,type], (err, results) => {
        if (err) return res.status(500).json({ error: "Database error",details:err });
        res.json(results);
    });
};
