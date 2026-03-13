const prisma = require('../config/prisma');
const { hashPassword, comparePassword } = require('../utils/hash');
const { signToken } = require('../utils/jwt');
const { sendVerificationEmail } = require('../utils/mailer');

const generateCode = () => Math.floor(100000 + Math.random() * 900000).toString();

const register = async ({ name, email, password, phone }) => {
  const existingUser = await prisma.user.findUnique({ where: { email } });

  if (existingUser) {
    throw new Error('Email đã tồn tại');
  }

  const hashedPassword = await hashPassword(password);
  const code = generateCode();
  const expires = new Date(Date.now() + 10 * 60 * 1000);

  const user = await prisma.user.create({
    data: {
      name,
      email,
      phone,
      password: hashedPassword,
      role: 'USER',
      emailVerifyCode: code,
      emailVerifyExpires: expires,
      emailVerified: false,
    },
  });

  await sendVerificationEmail(email, code, name);

  return {
    message: 'Đăng ký thành công. Vui lòng kiểm tra Gmail để xác nhận tài khoản.',
    email: user.email,
  };
};

const verifyEmail = async ({ email, code }) => {
  const user = await prisma.user.findUnique({ where: { email } });

  if (!user) {
    throw new Error('Không tìm thấy tài khoản');
  }

  if (user.emailVerified) {
    return { message: 'Email đã được xác nhận trước đó' };
  }

  if (!user.emailVerifyCode || !user.emailVerifyExpires) {
    throw new Error('Mã xác nhận không hợp lệ');
  }

  if (user.emailVerifyCode !== code) {
    throw new Error('Mã xác nhận sai');
  }

  if (new Date() > new Date(user.emailVerifyExpires)) {
    throw new Error('Mã xác nhận đã hết hạn');
  }

  await prisma.user.update({
    where: { email },
    data: {
      emailVerified: true,
      emailVerifyCode: null,
      emailVerifyExpires: null,
    },
  });

  return { message: 'Xác nhận email thành công' };
};

const resendVerification = async ({ email }) => {
  const user = await prisma.user.findUnique({ where: { email } });

  if (!user) {
    throw new Error('Không tìm thấy tài khoản');
  }

  if (user.emailVerified) {
    return { message: 'Email đã được xác nhận' };
  }

  const code = generateCode();
  const expires = new Date(Date.now() + 10 * 60 * 1000);

  await prisma.user.update({
    where: { email },
    data: {
      emailVerifyCode: code,
      emailVerifyExpires: expires,
    },
  });

  await sendVerificationEmail(email, code, user.name);

  return { message: 'Đã gửi lại mã xác nhận qua Gmail' };
};

const login = async ({ email, password }) => {
  const user = await prisma.user.findUnique({ where: { email } });

  console.log('LOGIN EMAIL:', email);
  console.log('LOGIN USER:', user);

  if (!user) {
    throw new Error('Email hoặc mật khẩu không đúng');
  }

  const isMatch = await comparePassword(password, user.password);
  console.log('PASSWORD MATCH:', isMatch);
  console.log('EMAIL VERIFIED:', user.emailVerified);

  if (!isMatch) {
    throw new Error('Email hoặc mật khẩu không đúng');
  }

  if (!user.emailVerified) {
    throw new Error('Tài khoản chưa xác nhận email');
  }

  const token = signToken({
    id: user.id,
    email: user.email,
    role: user.role,
  });

  return {
    user,
    token,
  };
};

module.exports = {
  register,
  verifyEmail,
  resendVerification,
  login,
};