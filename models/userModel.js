
const db = require("../config/db");

const User = {
    create: (data, callback) => {
        const sql = "INSERT INTO users (sin_num, name, phone_number, email, password, role) VALUES (?, ?, ?, ?, ?, ?)";
        db.query(sql, [data.sin_num, data.name, data.phone_number, data.email, data.password, data.role], callback);
    },

    findByEmail: (email, callback) => {
        const sql = "SELECT * FROM users WHERE email = ?";
        db.query(sql, [email], callback);
    }
};

module.exports = User;
