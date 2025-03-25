const db = require('../config/db');

class Food {
    static addFood(shop_id, name, price, availability, description, callback) {
        const sql = `INSERT INTO food_items (shop_id, name, price, availability, description) VALUES (?, ?, ?, ?, ?)`;
        db.query(sql, [shop_id, name, price, availability, description], callback);
    }

    static updateFood(id, name, price, availability, description, callback) {
        const sql = `UPDATE food_items SET name = ?, price = ?, availability = ?, description = ? WHERE id = ?`;
        db.query(sql, [name, price,parseInt(availability), description, id], callback);
    }
   

    static deleteFood(id, callback) {
        const sql = `DELETE FROM food_items WHERE id = ?`;
        db.query(sql, [id], callback);
    }

    static getFoodByShop(shop_id, callback) {
        const sql = `SELECT * FROM food_items WHERE shop_id = ? AND availability>0`;
        db.query(sql, [shop_id], callback);
    }
}

module.exports = Food;
