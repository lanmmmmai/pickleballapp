const express = require("express");
const userController = require("./user.controller");
const authMiddleware = require("../middleware/auth.middleware");
const roleMiddleware = require("../middleware/role.middleware");
const upload = require("../middleware/upload.middleware");

const router = express.Router();

router.get("/me", authMiddleware, userController.getMe);
router.put("/me", authMiddleware, userController.updateMe);
router.post("/me/avatar", authMiddleware, upload.single("avatar"), userController.updateAvatar);
router.post("/me/cover", authMiddleware, upload.single("cover"), userController.updateCover);
router.post("/me/payment-method-otp/request", authMiddleware, userController.requestPaymentMethodOtp);
router.post("/me/payment-method-otp/verify", authMiddleware, userController.verifyPaymentMethodOtp);

router.get("/", authMiddleware, roleMiddleware("ADMIN", "STAFF"), userController.getUsers);
router.get("/:id", authMiddleware, roleMiddleware("ADMIN", "STAFF"), userController.getUserById);
router.post("/", authMiddleware, roleMiddleware("ADMIN"), userController.createUser);
router.put("/:id", authMiddleware, roleMiddleware("ADMIN"), userController.updateUser);
router.patch("/:id/role", authMiddleware, roleMiddleware("ADMIN"), userController.updateUserRole);
router.post("/:id/avatar", authMiddleware, roleMiddleware("ADMIN"), upload.single("avatar"), userController.updateUserAvatarByAdmin);
router.delete("/:id/avatar", authMiddleware, roleMiddleware("ADMIN"), userController.deleteUserAvatarByAdmin);
router.delete("/:id", authMiddleware, roleMiddleware("ADMIN"), userController.deleteUser);

module.exports = router;
