const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_APP_PASSWORD,
  },
});

const sendVerificationEmail = async (toEmail, code, name) => {
  await transporter.sendMail({
    from: `"Tây Mỗ Pickleball Club" <${process.env.MAIL_USER}>`,
    to: toEmail,
    subject: 'Xác nhận tài khoản Tây Mỗ Pickleball Club',
    html: `
      <div style="font-family: Arial, sans-serif; line-height: 1.6;">
        <h2>Xin chào ${name || 'bạn'},</h2>
        <p>Cảm ơn bạn đã đăng ký tài khoản tại Tây Mỗ Pickleball Club.</p>
        <p>Mã xác nhận email của bạn là:</p>
        <h1 style="color: #0A7E4F; letter-spacing: 4px;">${code}</h1>
        <p>Mã có hiệu lực trong 10 phút.</p>
      </div>
    `,
  });
};

module.exports = {
  sendVerificationEmail,
};