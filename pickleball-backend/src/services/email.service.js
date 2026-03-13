const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.GMAIL_USER,
    pass: (process.env.GMAIL_APP_PASSWORD || "").replace(/\s+/g, ""),
  },
});


async function safeSend(mailOptions) {
  if (!process.env.GMAIL_USER || !(process.env.GMAIL_APP_PASSWORD || '').trim()) {
    return { skipped: true };
  }
  return transporter.sendMail(mailOptions);
}

async function sendOtpEmail({ to, name, otp }) {
  const html = `
    <div style="font-family: Arial, sans-serif; line-height: 1.6;">
      <h2>Xác nhận email - Pickleball Tây Mỗ Club</h2>
      <p>Xin chào ${name || "bạn"},</p>
      <p>Mã xác nhận email của bạn là:</p>
      <div style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #0f8b4c; margin: 16px 0;">${otp}</div>
      <p>Mã có hiệu lực trong ${process.env.OTP_EXPIRE_MINUTES || 5} phút.</p>
      <p>Nếu bạn không thực hiện yêu cầu này, hãy bỏ qua email.</p>
    </div>
  `;
  return safeSend({
    from: `"Pickleball Tây Mỗ Club" <${process.env.GMAIL_USER}>`,
    to,
    subject: "Mã xác nhận email của bạn",
    html,
  });
}

async function sendPaymentOtpEmail({ to, name, otp, method }) {
  const html = `
    <div style="font-family: Arial, sans-serif; line-height: 1.6;">
      <h2>Xác nhận thanh toán ${method}</h2>
      <p>Xin chào ${name || 'bạn'},</p>
      <p>Mã OTP cho giao dịch ${method} của bạn là:</p>
      <div style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #0f8b4c; margin: 16px 0;">${otp}</div>
      <p>Mã chỉ dùng cho giao dịch thanh toán hiện tại và hết hạn sau 5 phút.</p>
    </div>
  `;
  return safeSend({
    from: `"Pickleball Tây Mỗ Club" <${process.env.GMAIL_USER}>`,
    to,
    subject: `OTP thanh toán ${method}`,
    html,
  });
}

async function sendBookingBillEmail({ to, name, booking, extras = [], voucherCode, paymentMethod }) {
  const extrasHtml = extras.length
    ? `<ul>${extras.map((item) => `<li>${item.name} x${item.qty} - ${Number(item.price || 0).toFixed(0)}đ</li>`).join('')}</ul>`
    : '<p>Không có dịch vụ thêm.</p>';
  const html = `
    <div style="font-family: Arial, sans-serif; line-height: 1.6;">
      <h2>Hóa đơn đặt sân thành công</h2>
      <p>Xin chào ${name || 'bạn'},</p>
      <p>Bạn đã đặt sân thành công tại Tây Mỗ Pickleball Club.</p>
      <table cellpadding="8" cellspacing="0" style="border-collapse: collapse; width: 100%;">
        <tr><td><strong>Mã booking</strong></td><td>#${booking.id}</td></tr>
        <tr><td><strong>Sân</strong></td><td>${booking.court?.name || ''}</td></tr>
        <tr><td><strong>Ngày chơi</strong></td><td>${new Date(booking.bookingDate).toLocaleDateString('vi-VN')}</td></tr>
        <tr><td><strong>Khung giờ</strong></td><td>${booking.startTime} - ${booking.endTime}</td></tr>
        <tr><td><strong>Thanh toán</strong></td><td>${paymentMethod || 'Tiền mặt'}</td></tr>
        <tr><td><strong>Voucher</strong></td><td>${voucherCode || 'Không dùng'}</td></tr>
        <tr><td><strong>Tổng tiền</strong></td><td>${Number(booking.totalPrice || 0).toFixed(0)}đ</td></tr>
      </table>
      <h3>Dịch vụ thêm</h3>
      ${extrasHtml}
    </div>
  `;
  return safeSend({
    from: `"Pickleball Tây Mỗ Club" <${process.env.GMAIL_USER}>`,
    to,
    subject: `Hóa đơn đặt sân #${booking.id}`,
    html,
  });
}

module.exports = { sendOtpEmail, sendPaymentOtpEmail, sendBookingBillEmail };
