const crypto = require('crypto');
const prisma = require('../config/prisma');
const { sendPaymentOtpEmail } = require('../services/email.service');

const otpStore = new Map();

const requestPaymentOtp = async ({ userId, method }) => {
  const user = await prisma.user.findUnique({ where: { id: Number(userId) } });
  if (!user) throw new Error('Không tìm thấy người dùng');
  if (!user.email) throw new Error('Tài khoản chưa có email');
  const otp = String(Math.floor(100000 + Math.random() * 900000));
  const requestId = crypto.randomUUID();
  otpStore.set(requestId, {
    otp,
    userId: Number(userId),
    method,
    expiresAt: Date.now() + 5 * 60 * 1000,
  });
  let emailSent = false;
  try {
    await sendPaymentOtpEmail({ to: user.email, name: user.name, otp, method });
    emailSent = true;
  } catch (error) {
    console.error('[booking-payment-otp] send email failed:', error.message);
  }
  return {
    requestId,
    emailSent,
    debugOtp: process.env.NODE_ENV === 'production' ? undefined : otp,
  };
};

const verifyPaymentOtp = async ({ userId, requestId, otp }) => {
  const found = otpStore.get(requestId);
  if (!found || found.userId !== Number(userId)) throw new Error('Yêu cầu OTP không hợp lệ');
  if (found.expiresAt < Date.now()) {
    otpStore.delete(requestId);
    throw new Error('Mã OTP đã hết hạn');
  }
  if (String(found.otp) !== String(otp).trim()) throw new Error('Mã OTP không đúng');
  otpStore.delete(requestId);
  return { verified: true, method: found.method };
};

module.exports = { requestPaymentOtp, verifyPaymentOtp };
