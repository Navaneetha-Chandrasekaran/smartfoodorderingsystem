const db = require('../config/db');

class Shop {
    static createShop(name, callback) {
        const sql = `INSERT INTO shops (name) VALUES (?)`;
        db.query(sql, [name], callback);
    }

    static getAllShops(callback) {
        const sql = `SELECT * FROM shops`;
        db.query(sql, callback);
    }
}

module.exports = Shop;
