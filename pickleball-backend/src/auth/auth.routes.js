const express = require("express");
const controller = require("./auth.controller");

const router = express.Router();

router.post("/register", controller.register);
router.post("/verify-email-otp", controller.verifyEmailOtp);
router.post("/resend-email-otp", controller.resendEmailOtp);
router.post("/login", controller.login);

module.exports = router;