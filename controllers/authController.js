
const db = require('../config/db');
const bcrypt = require("bcryptjs");
const dotenv = require("dotenv");
const otpGenerator = require('otp-generator');
const sendOTP = require('../config/email');
const jwt = require('jsonwebtoken');

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

        const otp = otpGenerator.generate(4, {digits:true,alphabets: false, upperCase: false, specialChars: false });
        const sql = `INSERT INTO ${table} (name, email, phone, password, otp, is_verified) VALUES (?, ?, ?, ?, ?, false)`;
        db.query(sql, [name, email, phone, hashedPassword, otp], (err, result) => {
            if (err) return res.status(500).json({ message: 'Email already exists' });

            sendOTP(email, otp)
                .then(()=> res.json({ message: 'Registration successful. OTP sent to email.', email  }))
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
            const token = jwt.sign(
                { id: user.id, email: user.email, role: user.role },  // Add any other claims as needed
                process.env.JWT_SECRET,  // Ensure you have a secret key in your .env file
                { expiresIn: '30d' }  // Set expiration time for the token
            );

            res.json({  message: 'Login successful',
            userId: user.id,   // This is the ID from your DB
            token:token});
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


// 🔹 Resend OTP Function
exports.resendOTP = (req, res) => {
    const { email } = req.body; // Get email from request body

    // Validate that email exists
    if (!email) {
        return res.status(400).json({ message: 'Email is required to resend OTP.' });
    }

    // Check if the user exists in students or canteen_staff
    const checkStudentSql = `SELECT * FROM students WHERE email = ?`;
    const checkCanteenStaffSql = `SELECT * FROM canteen_staff WHERE email = ?`;

    // Check if the email exists in students table first
    db.query(checkStudentSql, [email], (err, studentResults) => {
        if (err) return res.status(500).json({ message: 'Database error while checking students email' });
        
        if (studentResults.length > 0) {
            // If user is found in students table, generate OTP and update the students table
            const otp = otpGenerator.generate(4, { digits: true, alphabets: false, specialChars: false });

            const updateOtpSql = `UPDATE students SET otp = ?, is_verified = false WHERE email = ?`;
            db.query(updateOtpSql, [otp, email], (err, result) => {
                if (err) return res.status(500).json({ message: 'Error updating OTP in students table', details: err });

                // Send OTP to email (assumes sendOTP function is set up correctly)
                sendOTP(email, otp)
                    .then(() => {
                        res.json({ message: 'OTP resent successfully to student. Please check your email.' });
                    })
                    .catch(() => {
                        res.status(500).json({ message: 'Failed to send OTP email.' });
                    });
            });
        } else {
            // If user is not found in students table, check in canteen_staff table
            db.query(checkCanteenStaffSql, [email], (err, staffResults) => {
                if (err) return res.status(500).json({ message: 'Database error while checking canteen staff email' });

                if (staffResults.length > 0) {
                    // If user is found in canteen_staff table, generate OTP and update the canteen_staff table
                    const otp = otpGenerator.generate(4, { digits: true, alphabets: false, specialChars: false });

                    const updateOtpSql = `UPDATE canteen_staff SET otp = ?, is_verified = false WHERE email = ?`;
                    db.query(updateOtpSql, [otp, email], (err, result) => {
                        if (err) return res.status(500).json({ message: 'Error updating OTP in canteen_staff table', details: err });

                        // Send OTP to email (assumes sendOTP function is set up correctly)
                        sendOTP(email, otp)
                            .then(() => {
                                res.json({ message: 'OTP resent successfully to canteen staff. Please check your email.' });
                            })
                            .catch(() => {
                                res.status(500).json({ message: 'Failed to send OTP email.' });
                            });
                    });
                } else {
                    return res.status(400).json({ message: 'User not found in both students and canteen_staff.' });
                }
            });
        }
    });
};
