const express = require("express");
const controller = require("./chatbot.controller");
const authMiddleware = require("../middleware/auth.middleware");

const router = express.Router();

router.post("/ask", authMiddleware, controller.askChatbot);

module.exports = router;