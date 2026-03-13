const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const prisma = require("../config/prisma");
const { sendOtpEmail } = require("../services/email.service");
const { getAvatarUrlByUserId } = require("../utils/avatarStore");

const hasColumn = async (columnName) => {
  const rows = await prisma.$queryRawUnsafe(`SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'User' AND column_name = '${columnName}' LIMIT 1`);
  return rows.length > 0;
};

const normalizeVerificationState = async (user) => {
  if (!user) return { verified: false };
  let verified = Boolean(user.emailVerified);
  try {
    if (!verified && await hasColumn('isVerified')) {
      const rows = await prisma.$queryRawUnsafe(`SELECT "isVerified" FROM "User" WHERE id = ${Number(user.id)} LIMIT 1`);
      if (rows.length) verified = Boolean(rows[0].isVerified);
    }
  } catch (error) {
    console.warn('[auth] normalizeVerificationState failed:', error.message);
  }
  return { verified };
};

function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

const register = async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;

    if (!name || !email || !phone || !password) {
      return res.status(400).json({ success: false, message: "Vui lòng nhập đầy đủ thông tin" });
    }

    const existingUser = await prisma.user.findFirst({ where: { OR: [{ email }, { phone }] } });
    if (existingUser) {
      return res.status(400).json({ success: false, message: "Email hoặc số điện thoại đã tồn tại" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const otp = generateOtp();
    const otpExpiresAt = new Date(Date.now() + 5 * 60 * 1000);

    const user = await prisma.user.create({
      data: {
        name,
        email,
        phone,
        password: hashedPassword,
        role: "USER",
        emailVerified: false,
        emailVerifyCode: otp,
        emailVerifyExpires: otpExpiresAt,
        paymentMethods: [],
      },
    });

    try {
      await sendOtpEmail({ to: user.email, name: user.name, otp });
    } catch (mailError) {
      console.error("Send OTP email error:", mailError);
      return res.status(500).json({ success: false, message: "Tạo tài khoản thành công nhưng gửi email OTP thất bại" });
    }

    return res.json({
      success: true,
      message: "Đăng ký thành công. Vui lòng kiểm tra email để lấy mã xác nhận.",
      data: { email: user.email },
    });
  } catch (error) {
    console.error("Register error:", error);
    return res.status(500).json({ success: false, message: "Lỗi đăng ký tài khoản" });
  }
};

const verifyEmailOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ success: false, message: "Thiếu email hoặc mã OTP" });

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) return res.status(404).json({ success: false, message: "Không tìm thấy tài khoản" });
    if (user.emailVerified) return res.status(400).json({ success: false, message: "Email đã được xác nhận" });
    if (!user.emailVerifyCode || !user.emailVerifyExpires) return res.status(400).json({ success: false, message: "Chưa có mã OTP hoặc mã không hợp lệ" });
    if (new Date() > new Date(user.emailVerifyExpires)) return res.status(400).json({ success: false, message: "Mã OTP đã hết hạn" });
    if (user.emailVerifyCode !== otp) return res.status(400).json({ success: false, message: "Mã OTP không đúng" });

    await prisma.user.update({ where: { id: user.id }, data: { emailVerified: true, emailVerifyCode: null, emailVerifyExpires: null } });
    return res.json({ success: true, message: "Xác nhận email thành công" });
  } catch (error) {
    console.error("Verify OTP error:", error);
    return res.status(500).json({ success: false, message: "Lỗi xác nhận OTP" });
  }
};

const resendEmailOtp = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ success: false, message: "Thiếu email" });

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) return res.status(404).json({ success: false, message: "Không tìm thấy tài khoản" });
    if (user.emailVerified) return res.status(400).json({ success: false, message: "Email đã được xác nhận" });

    const otp = generateOtp();
    const otpExpiresAt = new Date(Date.now() + 5 * 60 * 1000);
    await prisma.user.update({ where: { id: user.id }, data: { emailVerifyCode: otp, emailVerifyExpires: otpExpiresAt } });

    try {
      await sendOtpEmail({ to: user.email, name: user.name, otp });
    } catch (mailError) {
      console.error("Resend OTP email error:", mailError);
      return res.status(500).json({ success: false, message: "Gửi lại OTP thất bại" });
    }

    return res.json({ success: true, message: "Đã gửi lại mã OTP" });
  } catch (error) {
    console.error("Resend OTP error:", error);
    return res.status(500).json({ success: false, message: "Lỗi gửi lại OTP" });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ success: false, message: "Vui lòng nhập email và mật khẩu" });

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) return res.status(400).json({ success: false, message: "Email hoặc mật khẩu không đúng" });

    let isMatch = false;
    try {
      if (typeof user.password === 'string' && user.password.startsWith('$2')) {
        isMatch = await bcrypt.compare(password, user.password);
      } else {
        isMatch = user.password === password;
      }
    } catch (compareError) {
      console.warn('[auth] bcrypt compare failed, fallback plain compare:', compareError.message);
      isMatch = user.password === password;
    }

    if (!isMatch) return res.status(400).json({ success: false, message: "Email hoặc mật khẩu không đúng" });

    const verification = await normalizeVerificationState(user);
    if (!verification.verified) {
      return res.status(403).json({ success: false, message: "Email chưa được xác nhận" });
    }

    const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, process.env.JWT_SECRET || "secret", { expiresIn: process.env.JWT_EXPIRES_IN || "7d" });

    return res.json({
      success: true,
      message: "Đăng nhập thành công",
      data: {
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          role: user.role,
          paymentMethods: user.paymentMethods || [],
          emailVerified: Boolean(user.emailVerified || verification.verified),
          avatarUrl: getAvatarUrlByUserId(user.id),
        },
      },
    });
  } catch (error) {
    console.error("Login error:", error);
    return res.status(500).json({ success: false, message: error.message || "Lỗi đăng nhập" });
  }
};

module.exports = { register, verifyEmailOtp, resendEmailOtp, login };
