const express = require("express");
const notificationController = require("./notification.controller");
const authMiddleware = require("../middleware/auth.middleware");
const roleMiddleware = require("../middleware/role.middleware");
const upload = require("../middleware/upload.middleware");

const router = express.Router();

router.get("/", authMiddleware, notificationController.getNotifications);
router.get("/:id", authMiddleware, notificationController.getNotificationById);

router.post(
  "/",
  authMiddleware,
  roleMiddleware("ADMIN", "STAFF"),
  upload.single("image"),
  notificationController.createNotification
);

router.put(
  "/:id",
  authMiddleware,
  roleMiddleware("ADMIN", "STAFF"),
  upload.single("image"),
  notificationController.updateNotification
);

router.delete(
  "/:id",
  authMiddleware,
  roleMiddleware("ADMIN"),
  notificationController.deleteNotification
);

module.exports = router;