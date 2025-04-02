// const db = require("../config/db");

// const Food = {
//     // Add Food Item
//     addFood: (shop_id, name, description, price, image, callback) => {
//         const sql = `INSERT INTO food_items (shop_id, name, description, price, image) VALUES (?, ?, ?, ?, ?)`;
//         db.query(sql, [shop_id, name, description, price, image], callback);
//     },

//     // Update Food Item
//     updateFood: (food_id, name, description, price, image, callback) => {
//         const sql = `UPDATE food_items SET name = ?, description = ?, price = ?, image = ? WHERE id = ?`;
//         db.query(sql, [name, description, price, image, food_id], callback);
//     },

//     // Delete Food Item
//     deleteFood: (food_id, callback) => {
//         const sql = `DELETE FROM food_items WHERE id = ?`;
//         db.query(sql, [food_id], callback);
//     },

//     // Fetch All Food Items for Admin (All Shops)
//     getAllFoods: (callback) => {
//         const sql = `SELECT * FROM food_items`;
//         db.query(sql, callback);
//     },

//     // Fetch Food Items by Shop ID
//     getFoodByShop: (shop_id, callback) => {
//         const sql = `SELECT * FROM food_items WHERE shop_id = ?`;
//         db.query(sql, [shop_id], callback);
//     }
// };

// module.exports = Food;




// class Food {
//     static addFood(shop_id, name, price, availability, description, callback) {
//         const sql = `INSERT INTO food_items (shop_id, name, price, availability, description) VALUES (?, ?, ?, ?, ?)`;
//         db.query(sql, [shop_id, name, price, availability, description], callback);
//     }

//     static updateFood(id, name, price, availability, description, callback) {
//         const sql = `UPDATE food_items SET name = ?, price = ?, availability = ?, description = ? WHERE id = ?`;
//         db.query(sql, [name, price,parseInt(availability), description, id], callback);
//     }
   

//     static deleteFood(id, callback) {
//         const sql = `DELETE FROM food_items WHERE id = ?`;
//         db.query(sql, [id], callback);
//     }

//     static getFoodByShop(shop_id, callback) {
//         const sql = `SELECT * FROM food_items WHERE shop_id = ? AND availability>0`;
//         db.query(sql, [shop_id], callback);
//     }
// }

// module.exports = Food;
