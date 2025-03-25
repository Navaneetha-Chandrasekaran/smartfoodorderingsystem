const express = require("express");
const dotenv = require("dotenv");
const cors = require("cors");
dotenv.config();
const db = require("./config/db");
const app = express();
const foodRoutes = require("./routes/foodRoute");
const shopRoutes = require('./routes/shopRoutes');

// Middleware
app.use(cors());
app.use(express.json());
// Routes
app.use("/api/auth", require("./routes/authRoutes"));
app.use('/api/shop', shopRoutes);
app.use("/api/food", foodRoutes);
app.use("/api/orders", require("./routes/orderRoute"));
// Start Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
