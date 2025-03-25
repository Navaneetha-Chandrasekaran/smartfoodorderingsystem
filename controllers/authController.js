
const db = require('../config/db');
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/userModel");
const dotenv = require("dotenv");
const otpGenerator = require('otp-generator');
const sendOTP = require('../config/email');

dotenv.config();

exports.registerStudent = (req, res) => {
    const { name, email, phone, password, confirmPassword } = req.body;

    if (!email.endsWith('@shanmugha.edu.in')) {
        return res.status(400).json({ message: 'Email must be from shanmugha.edu.in domain' });
    }

    registerUser('students', name, email, phone, password, confirmPassword, res);
};

// 🔹 Canteen Staff Registration
exports.registerStaff = (req, res) => {
    const { name, email, phone, password, confirmPassword } = req.body;

    registerUser('canteen_staff', name, email, phone, password, confirmPassword, res);
};

// 🔹 Common Registration Function
const registerUser = (table, name, email, phone, password, confirmPassword, res) => {
    if (!/^\d{10}$/.test(phone)) {
        return res.status(400).json({ message: 'Phone number must be 10 digits' });
    }

    if (password.length < 8) {
        return res.status(400).json({ message: 'Password must be at least 8 characters long' });
    }

    if (password !== confirmPassword) {
        return res.status(400).json({ message: 'Passwords do not match' });
    }

    bcrypt.hash(password, 10, (err, hashedPassword) => {
        if (err) return res.status(500).json({ message: 'Error hashing password' });

        const otp = otpGenerator.generate(6, { upperCase: false, specialChars: false });

        const sql = `INSERT INTO ${table} (name, email, phone, password, otp, is_verified) VALUES (?, ?, ?, ?, ?, false)`;
        db.query(sql, [name, email, phone, hashedPassword, otp], (err, result) => {
            if (err) return res.status(500).json({ message: 'Email already exists' });

            sendOTP(email, otp)
                .then(() => res.json({ message: 'Registration successful. OTP sent to email.', email }))
                .catch(() => res.status(500).json({ message: 'Failed to send OTP' }));
                
                      

        });
    });
};

// 🔹 OTP Verification
exports.verifyOTP = (req, res) => {
    const { email, otp } = req.body;

    // First, check in students table
    const studentSql = `SELECT otp FROM students WHERE email = ?`;
    
    db.query(studentSql, [email], (err, studentResults) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ message: 'Database error while verifying OTP' });
        }

        if (studentResults.length > 0) {
            // If OTP matches for student, update verification status
            if (studentResults[0].otp === otp) {
                const updateStudentSql = `UPDATE students SET is_verified = true WHERE email = ?`;
                db.query(updateStudentSql, [email], (err, result) => {
                    if (err) {
                        console.error('Error updating student verification:', err);
                        return res.status(500).json({ message: 'Error updating verification status' });
                    }
                    return res.json({ message: 'Student email verified successfully' });
                });
            } else {
                return res.status(400).json({ message: 'Invalid OTP' });
            }
        } else {
            // If not found in students, check in canteen_staff
            const staffSql = `SELECT otp FROM canteen_staff WHERE email = ?`;
            db.query(staffSql, [email], (err, staffResults) => {
                if (err) {
                    console.error('Database error:', err);
                    return res.status(500).json({ message: 'Database error while verifying OTP' });
                }

                if (staffResults.length > 0) {
                    // If OTP matches for staff, update verification status
                    if (staffResults[0].otp === otp) {
                        const updateStaffSql = `UPDATE canteen_staff SET is_verified = true WHERE email = ?`;
                        db.query(updateStaffSql, [email], (err, result) => {
                            if (err) {
                                console.error('Error updating staff verification:', err);
                                return res.status(500).json({ message: 'Error updating verification status' });
                            }
                            return res.json({ message: 'Canteen staff email verified successfully' });
                        });
                    } else {
                        return res.status(400).json({ message: 'Invalid OTP' });
                    }
                } else {
                    return res.status(400).json({ message: 'Email not found' });
                }
            });
        }
    });
};



// 🔹 User Login
exports.loginUser = (req, res) => {
    const { email, password } = req.body;

    const sql = `
        SELECT * FROM students WHERE email = ?
        UNION
        SELECT * FROM canteen_staff WHERE email = ?
    `;
   

    db.query(sql, [email, email], (err, results) => {
        if (err || results.length === 0) {
            return res.status(400).json({ message: 'User not found' });
        }

        const user = results[0];

        if (!user.is_verified) {
            return res.status(403).json({ message: 'Email not verified' });
        }

        bcrypt.compare(password, user.password, (err, match) => {
            if (!match) {
                return res.status(401).json({ message: 'Incorrect password' });
            }

            res.json({ message: 'Login successful', role: user.role });
        });
    });
};


//reset password

exports.resetPassword = async (req, res) => {
    try {
        const { email, newPassword, confirmPassword } = req.body;

        // Validate input fields
        if (!email || !newPassword || !confirmPassword) {
            return res.status(400).json({ message: "All fields are required" });
        }

        if (newPassword.length < 8) {
            return res.status(400).json({ message: "Password must be at least 8 characters long" });
        }

        if (newPassword !== confirmPassword) {
            return res.status(400).json({ message: "Passwords do not match" });
        }

        // Hash the new password
        const hashedPassword = await bcrypt.hash(newPassword, 10);

        // Check if user exists in the `students` table
        db.query(`SELECT id FROM students WHERE email = ?`, [email], (err, studentResults) => {
            if (err) return res.status(500).json({ message: "Database error", error: err });

            if (studentResults.length > 0) {
                // Update student password
                db.query(`UPDATE students SET password = ? WHERE email = ?`, [hashedPassword, email], (err) => {
                    if (err) return res.status(500).json({ message: "Failed to update student password", error: err });

                    return res.json({ message: "Password reset successful" });
                });
            } else {
                // Check if user exists in the `canteen_staff` table
                db.query(`SELECT id FROM canteen_staff WHERE email = ?`, [email], (err, staffResults) => {
                    if (err) return res.status(500).json({ message: "Database error", error: err });

                    if (staffResults.length > 0) {
                        // Update staff password
                        db.query(`UPDATE canteen_staff SET password = ? WHERE email = ?`, [hashedPassword, email], (err) => {
                            if (err) return res.status(500).json({ message: "Failed to update staff password", error: err });

                            return res.json({ message: "Password reset successful" });
                        });
                    } else {
                        return res.status(404).json({ message: "User not found" });
                    }
                });
            }
        });
    } catch (error) {
        res.status(500).json({ message: "Server error", error });
    }
};
