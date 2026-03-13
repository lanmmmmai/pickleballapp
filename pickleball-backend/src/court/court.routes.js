const express = require("express");
const courtController = require("./court.controller");
const authMiddleware = require("../middleware/auth.middleware");
const roleMiddleware = require("../middleware/role.middleware");
const upload = require("../middleware/upload.middleware");

const router = express.Router();

router.get("/", courtController.getCourts);

router.post(
  "/",
  authMiddleware,
  roleMiddleware("ADMIN", "STAFF"),
  upload.single("image"),
  courtController.createCourt
);

router.put(
  "/:id",
  authMiddleware,
  roleMiddleware("ADMIN", "STAFF"),
  upload.single("image"),
  courtController.updateCourt
);

router.delete(
  "/:id",
  authMiddleware,
  roleMiddleware("ADMIN"),
  courtController.deleteCourt
);

module.exports = router;