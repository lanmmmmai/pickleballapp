const express = require("express");
const cors = require("cors");
require("dotenv").config();
const path = require("path");

const authRoutes = require("./auth/auth.routes");
const bookingRoutes = require("./booking/booking.routes");
const chatbotRoutes = require("./chatbot/chatbot.routes");
const coachRoutes = require("./coach/coach.routes");
const courtRoutes = require("./court/court.routes");
const notificationRoutes = require("./notification/notification.routes");
const spinRoutes = require("./spin/spin.routes");
const userRoutes = require("./user/user.routes");
const videoRoutes = require("./video/video.routes");
const voucherRoutes = require("./voucher/voucher.routes");
const coinRoutes = require("./coin/coin.routes");
const dashboardRoutes = require("./dashboard/dashboard.routes");
const productRoutes = require("./product/product.routes");
const classRoutes = require("./class/class.routes");
const postRoutes = require("./post/post.routes");
const errorMiddleware = require("./middleware/error.middleware");

const app = express();

app.use(cors());
app.use(express.json());
app.use("/uploads", express.static(path.join(__dirname, "../uploads")));

app.get("/", (req, res) => {
  res.json({ message: "Pickleball backend is running" });
});

app.use("/api/auth", authRoutes);
app.use("/api/bookings", bookingRoutes);
app.use("/api/chatbot", chatbotRoutes);
app.use("/api/coaches", coachRoutes);
app.use("/api/courts", courtRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/spin", spinRoutes);
app.use("/api/users", userRoutes);
app.use("/api/videos", videoRoutes);
app.use("/api/vouchers", voucherRoutes);
app.use("/api/coins", coinRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/products", productRoutes);
app.use("/api/classes", classRoutes);
app.use("/api/posts", postRoutes);

app.use(errorMiddleware);

module.exports = app;