const jwt = require('jsonwebtoken');
const { has } = require('./tokenBlacklist');

const verify = (req, res, next) => {
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'ไม่พบ Token' });
  }

  const token = authHeader.split(' ')[1];

  // เช็ค blacklist ก่อน
  if (has(token)) {
    return res.status(401).json({ message: 'Token ถูก logout แล้ว' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Token ไม่ถูกต้องหรือหมดอายุ' });
  }
};

module.exports = verify;