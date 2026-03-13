const express = require("express");
const bookingController = require("./booking.controller");
const authMiddleware = require("../middleware/auth.middleware");
const roleMiddleware = require("../middleware/role.middleware");

const router = express.Router();
router.get('/', authMiddleware, roleMiddleware('ADMIN','STAFF'), bookingController.getBookings);
router.get('/me', authMiddleware, bookingController.getMyBookings);
router.post('/', authMiddleware, bookingController.createBooking);
router.post('/payment-otp/request', authMiddleware, bookingController.requestPaymentOtp);
router.post('/payment-otp/verify', authMiddleware, bookingController.verifyPaymentOtp);
router.get('/:id', authMiddleware, bookingController.getBookingById);
router.patch('/:id/status', authMiddleware, roleMiddleware('ADMIN','STAFF'), bookingController.updateBookingStatus);
router.post('/:id/checkin', authMiddleware, roleMiddleware('ADMIN','STAFF'), bookingController.checkInBooking);
router.post('/:id/no-show', authMiddleware, roleMiddleware('ADMIN','STAFF'), bookingController.noShowBooking);
router.delete('/:id', authMiddleware, roleMiddleware('ADMIN'), bookingController.deleteBooking);
module.exports = router;
