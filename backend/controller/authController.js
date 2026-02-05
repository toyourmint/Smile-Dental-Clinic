const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
//const pool = require('../config/db');

const mysql = require('mysql2/promise');
const nodemailer = require('nodemailer');

// let mockOtpDB = {};

// ================= DB CONFIG =================
const dbConfig = {
    host: 'db',
    port: 3306,
    user: 'root',
    password: 'root',
    database: 'clinic_db'
};

// ================= EMAIL CONFIG =================
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'napapat0564@gmail.com',
        pass: 'ihrn ofsh vaox qiun'
    }
});

// =================================================
// REGISTER
// =================================================
exports.register = async (req, res) => {
    const {
        citizen_id, title, first_name, last_name, birth_date, gender,
        email, phone,
        address_line, subdistrict, district, province, postal_code
    } = req.body;

    if (!email || !phone || !citizen_id || !first_name) {
        return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
    }

    const connection = await mysql.createConnection(dbConfig);

    try {
        await connection.beginTransaction();

        // 1. check duplicate
        const [existing] = await connection.execute(
            'SELECT id FROM users WHERE email = ? OR phone = ?',
            [email, phone]
        );

        if (existing.length > 0) {
            await connection.rollback();
            await connection.end();
            return res.status(400).json({ message: 'Email หรือเบอร์โทรนี้ลงทะเบียนไปแล้ว' });
        }

        // 2. create user (password = PENDING)
        const [userResult] = await connection.execute(
            'INSERT INTO users (email, phone, password, role, is_active) VALUES (?, ?, ?, ?, ?)',
            [email, phone, 'PENDING', 'user', 0]
        );
        const userId = userResult.insertId;

        // 3. profile
        await connection.execute(
            `INSERT INTO user_profiles 
            (user_id, citizen_id, title, first_name, last_name, birth_date, gender)
            VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [userId, citizen_id, title, first_name, last_name, birth_date, gender]
        );

        // 4. address
        await connection.execute(
            `INSERT INTO user_addresses
            (user_id, address_line, subdistrict, district, province, postal_code)
            VALUES (?, ?, ?, ?, ?, ?)`,
            [userId, address_line, subdistrict, district, province, postal_code]
        );

        // 5. OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

        await connection.execute(
            'INSERT INTO user_otps (user_id, otp_code, expires_at, is_used) VALUES (?, ?, ?, 0)',
            [userId, otp, expiresAt]
        );

        await connection.commit();
        await connection.end();

        // 6. send email
        await transporter.sendMail({
            from: 'Smile Dental Admin',
            to: email,
            subject: 'รหัส OTP สำหรับลงทะเบียน',
            html: `รหัส OTP คือ <b>${otp}</b>`
        });

        res.json({ message: 'บันทึกข้อมูลและส่ง OTP เรียบร้อยแล้ว' });

    } catch (error) {
        await connection.rollback();
        await connection.end();
        console.error(error);
        res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
    }
};

// =================================================
// LOGIN  ✅ FIX bcrypt + PENDING
// =================================================
exports.login = async (req, res) => {
    const { loginIdentifier, password } = req.body;

    if (!loginIdentifier || !password) {
        return res.status(400).json({ message: "กรุณากรอก Email/เบอร์โทร และรหัสผ่าน" });
    }

    try {
        const connection = await mysql.createConnection(dbConfig);

        const [rows] = await connection.execute(
            'SELECT * FROM users WHERE (email = ? OR phone = ?) AND is_active = 1',
            [loginIdentifier, loginIdentifier]
        );

        await connection.end();

        if (rows.length === 0) {
            return res.status(401).json({
                message: "ไม่พบผู้ใช้ หรือบัญชียังไม่ถูกเปิดใช้งาน"
            });
        }

        const user = rows[0];

        // 🔴 FIX: ป้องกัน bcrypt พัง
        if (user.password === 'PENDING') {
            return res.status(403).json({
                message: 'บัญชียังไม่ได้ตั้งรหัสผ่าน กรุณายืนยัน OTP ก่อน'
            });
        }

        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(401).json({ message: "รหัสผ่านไม่ถูกต้อง" });
        }

        const token = jwt.sign(
            {
                userId: user.id,
                email: user.email,
                role: user.role
            },
            process.env.JWT_SECRET || 'secret_key',
            { expiresIn: '8h' }
        );

        res.status(200).json({
            message: 'เข้าสู่ระบบสำเร็จ',
            token,
            user: {
                id: user.id,
                email: user.email,
                role: user.role
            }
        });

    } catch (error) {
        console.error('Login Error:', error);
        res.status(500).json({ message: 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ' });
    }
};

// =================================================
// FORGOT PASSWORD
// =================================================
exports.requestPasswordReset = async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'กรุณากรอกอีเมล' });
    }

    try {
        const connection = await mysql.createConnection(dbConfig);

        const [users] = await connection.execute(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            await connection.end();
            return res.status(404).json({ message: 'ไม่พบอีเมลนี้ในระบบ' });
        }

        const userId = users[0].id;
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

        await connection.execute(
            'UPDATE user_otps SET is_used = 1 WHERE user_id = ?',
            [userId]
        );

        await connection.execute(
            'INSERT INTO user_otps (user_id, otp_code, expires_at, is_used) VALUES (?, ?, ?, 0)',
            [userId, otp, expiresAt]
        );

        await connection.end();

        await transporter.sendMail({
            from: 'Smile Dental Admin',
            to: email,
            subject: 'OTP สำหรับตั้งรหัสผ่านใหม่',
            html: `รหัส OTP คือ <b>${otp}</b>`
        });

        res.json({ message: 'ส่ง OTP ไปยังอีเมลเรียบร้อยแล้ว' });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
    }
};

// =================================================
// VERIFY OTP
// =================================================
exports.verifyOtp = async (req, res) => {
    const { email, otp } = req.body;

    try {
        const connection = await mysql.createConnection(dbConfig);

        const [users] = await connection.execute(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            await connection.end();
            return res.status(404).json({ message: 'ไม่พบผู้ใช้' });
        }

        const userId = users[0].id;

        const [rows] = await connection.execute(
            `SELECT id FROM user_otps
             WHERE user_id = ? AND otp_code = ? AND is_used = 0 AND expires_at > NOW()`,
            [userId, otp]
        );

        await connection.end();

        if (rows.length === 0) {
            return res.status(400).json({ message: 'OTP ไม่ถูกต้องหรือหมดอายุ' });
        }

        res.json({ message: 'OTP ถูกต้อง' });

    } catch (error) {
        res.status(500).json({ message: 'Error checking OTP' });
    }
};

// =================================================
// SET PASSWORD  ✅ FIX confirmPassword
// =================================================
exports.setPassword = async (req, res) => {
    const { email, password, otp } = req.body;

    if (!password || password.length < 6) {
        return res.status(400).json({
            message: 'รหัสผ่านต้องอย่างน้อย 6 ตัวอักษร'
        });
    }

    try {
        const connection = await mysql.createConnection(dbConfig);

        const [users] = await connection.execute(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            await connection.end();
            return res.status(404).json({ message: 'User not found' });
        }

        const userId = users[0].id;

        const [otpRows] = await connection.execute(
            `SELECT id FROM user_otps
             WHERE user_id = ? AND otp_code = ? AND is_used = 0 AND expires_at > NOW()`,
            [userId, otp]
        );

        if (otpRows.length === 0) {
            await connection.end();
            return res.status(400).json({
                message: 'รหัส OTP ไม่ถูกต้องหรือหมดอายุ'
            });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        await connection.execute(
            'UPDATE users SET password = ?, is_active = 1 WHERE id = ?',
            [hashedPassword, userId]
        );

        await connection.execute(
            'UPDATE user_otps SET is_used = 1 WHERE id = ?',
            [otpRows[0].id]
        );

        await connection.end();

        res.json({ message: 'ตั้งรหัสผ่านเรียบร้อยแล้ว' });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error setting password' });
    }
};
exports.resendOtp = async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'กรุณาระบุ Email' });
    }

    try {
        const connection = await mysql.createConnection(dbConfig);

        const [users] = await connection.execute(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            await connection.end();
            return res.status(404).json({ message: 'ไม่พบผู้ใช้' });
        }

        const userId = users[0].id;

        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

        await connection.execute(
            'UPDATE user_otps SET is_used = 1 WHERE user_id = ? AND is_used = 0',
            [userId]
        );

        await connection.execute(
            'INSERT INTO user_otps (user_id, otp_code, expires_at, is_used) VALUES (?, ?, ?, 0)',
            [userId, otp, expiresAt]
        );

        await connection.end();

        await transporter.sendMail({
            from: 'Smile Dental Admin',
            to: email,
            subject: 'รหัส OTP ใหม่',
            html: `รหัส OTP ใหม่คือ <b>${otp}</b>`
        });

        res.json({ message: 'ส่งรหัส OTP ใหม่เรียบร้อยแล้ว' });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'ส่ง OTP ไม่สำเร็จ' });
    }
};
