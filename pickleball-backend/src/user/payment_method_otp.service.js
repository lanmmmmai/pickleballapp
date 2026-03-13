const prisma = require('../config/prisma');
const { readJson, writeJson } = require('../utils/jsonStore');
const { sendPaymentOtpEmail } = require('../services/email.service');

const STORE_PATH = 'data/payment_method_otps.json';

const getStore = () => readJson(STORE_PATH, []);
const saveStore = (items) => writeJson(STORE_PATH, items);
const generateOtp = () => Math.floor(100000 + Math.random() * 900000).toString();

function normalizeMethod(method) {
  const allowed = ['MoMo', 'ZaloPay', 'Chuyển khoản QR', 'Banking'];
  if (!method) return 'Chuyển khoản QR';
  return allowed.includes(method) ? method : 'Chuyển khoản QR';
}

function maskAccount(account = '') {
  const text = String(account).trim();
  if (text.length <= 4) return text;
  return `${'*'.repeat(Math.max(0, text.length - 4))}${text.slice(-4)}`;
}

async function requestPaymentMethodOtp({ userId, method, account }) {
  const uid = Number(userId);
  if (!uid) throw new Error('Thiếu userId hợp lệ');

  const user = await prisma.user.findUnique({
    where: { id: uid },
  });

  if (!user) throw new Error('Không tìm thấy người dùng');
  if (!user.email) throw new Error('Tài khoản chưa có email để nhận OTP');

  const finalMethod = normalizeMethod(method);
  const finalAccount = String(account || '').trim();

  if (!finalAccount) {
    throw new Error('Vui lòng nhập số tài khoản / số ví');
  }

  const otp = generateOtp();
  const requestId = `pm_${Date.now()}_${uid}`;

  let items = getStore();
  items = items.filter(
    (i) =>
      !(
        Number(i.userId) === uid &&
        i.verified !== true
      )
  );

  items.unshift({
    requestId,
    userId: uid,
    method: finalMethod,
    account: finalAccount,
    otp,
    expiresAt: Date.now() + 5 * 60 * 1000,
    verified: false,
    createdAt: Date.now(),
  });

  saveStore(items);

  let emailSent = false;
  let emailError = null;

  try {
    await sendPaymentOtpEmail({
      to: user.email,
      name: user.name || user.fullName || 'bạn',
      otp,
      method: finalMethod,
    });
    emailSent = true;
  } catch (error) {
    emailError = error?.message || 'Không gửi được email OTP';
    console.error('[payment-method-otp] send email failed:', error);
  }

  return {
    success: true,
    requestId,
    emailSent,
    message: emailSent
      ? 'Đã gửi OTP về Gmail'
      : 'Không gửi được email OTP, vui lòng kiểm tra cấu hình Gmail backend',
    debugOtp: process.env.NODE_ENV === 'production' ? undefined : otp,
    maskedAccount: maskAccount(finalAccount),
    method: finalMethod,
    emailError,
  };
}

async function verifyPaymentMethodOtp({ userId, requestId, otp }) {
  const uid = Number(userId);
  if (!uid) throw new Error('Thiếu userId hợp lệ');
  if (!requestId) throw new Error('Thiếu requestId');
  if (!otp) throw new Error('Vui lòng nhập OTP');

  const items = getStore();
  const idx = items.findIndex(
    (i) => i.requestId === requestId && Number(i.userId) === uid
  );

  if (idx < 0) throw new Error('Không tìm thấy yêu cầu OTP');

  const item = items[idx];

  if (item.verified === true) {
    return {
      success: true,
      method: item.method,
      account: item.account,
      label: `${item.method} • ${item.account}`,
      maskedAccount: maskAccount(item.account),
      alreadyVerified: true,
    };
  }

  if (Number(item.expiresAt) < Date.now()) {
    throw new Error('OTP đã hết hạn');
  }

  if (String(item.otp).trim() !== String(otp).trim()) {
    throw new Error('OTP không đúng');
  }

  items[idx].verified = true;
  items[idx].verifiedAt = Date.now();
  saveStore(items);

  return {
    success: true,
    method: item.method,
    account: item.account,
    label: `${item.method} • ${item.account}`,
    maskedAccount: maskAccount(item.account),
  };
}

module.exports = {
  requestPaymentMethodOtp,
  verifyPaymentMethodOtp,
};