const express = require("express");
const coinController = require("./coin.controller");
const authMiddleware = require("../middleware/auth.middleware");
const roleMiddleware = require("../middleware/role.middleware");

const router = express.Router();
router.get("/users", authMiddleware, roleMiddleware("ADMIN", "STAFF"), coinController.getUsersWithCoin);
router.get("/transactions", authMiddleware, roleMiddleware("ADMIN", "STAFF"), coinController.getCoinTransactions);
router.get('/history/me', authMiddleware, coinController.getMyHistory);
router.get('/vouchers/me', authMiddleware, coinController.getMyVouchers);
router.get("/tasks", authMiddleware, coinController.getTasks);
router.post("/tasks", authMiddleware, roleMiddleware('ADMIN'), coinController.createTask);
router.delete("/tasks/:id", authMiddleware, roleMiddleware('ADMIN'), coinController.deleteTask);
router.post("/tasks/:id/claim", authMiddleware, coinController.claimTask);

module.exports = router;
