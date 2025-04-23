const express = require("express");
const dotenv = require("dotenv");
const cors = require("cors");
dotenv.config();
const db = require("./config/db");
const app = express();
const http = require("http");  // Required for Socket.IO
const { Server } = require("socket.io");  // Import Socket.IO

const shopRoutes = require('./routes/shopRoutes');
const adminRoute=require('./routes/adminRoute');
const foodRoute=require("./routes/foodRoute");
const cartRoute=require('./routes/cartRoutes');


// Middleware
app.use(cors());
app.use(express.json());
// Routes
app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/admin",adminRoute);
app.use('/api/shop', shopRoutes);
app.use("/api/food", foodRoute);
app.use("/api/cart",cartRoute);
app.use("/api/orders", require("./routes/orderRoute"));

// Create HTTP Server
const server = http.createServer(app);

// Initialize Socket.io
const io = new Server(server, {
    cors: {
        origin: "*", 
        methods: ["GET", "POST"]
    }
});

// Store io globally to use in controllers
global.io = io;

// Handle WebSocket Connections
io.on("connection", (socket) => {
    console.log("New WebSocket connection:", socket.id);
     
        // User joins a room based on their user_id
        socket.on("join_user", (user_id) => {
            socket.join(`user_${user_id}`);
            console.log(`User joined Personal Room: user_${user_id}`);
        });
        //canteen staff
    socket.on("join_canteen", (shop_id) => {
        socket.join(`canteen_${shop_id}`);
        console.log(`User joined Canteen Room: canteen_${shop_id}`);
    });
    socket.on("shop_status_change", ({ shop_id, status }) => {
        // Broadcast to all clients in that shop room
        io.to(`canteen_${shop_id}`).emit("shop_status_update", {
            shop_id,
            status
        });
        console.log(`Shop status updated for shop ${shop_id}: ${status}`);
    });

    socket.on("disconnect", () => {
        console.log("User disconnected:", socket.id);
    });
});
// Start Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
