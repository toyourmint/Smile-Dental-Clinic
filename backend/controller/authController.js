const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
//const pool = require('../config/db');

const mysql = require('mysql2/promise');
const nodemailer = require('nodemailer');

// let mockOtpDB = {};

// --- ตั้งค่า Database และ Email (ควรแยกไฟล์ Config แต่ใส่ตรงนี้ก่อนได้ครับ) ---
const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: 'root',
    database: 'clinic_db' // เปลี่ยนเป็นชื่อ DB ของคุณ
};

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'napapat0564@gmail.com', // อีเมลคุณ
        pass: 'ihrn ofsh vaox qiun'   // App Password
    }
});

exports.register = async (req, res) => {
    const { email, phone, password, confirmPassword } = req.body;

    if (!email || !phone || !password) {
        return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
    }

    if (password !== confirmPassword) {
        return res.status(400).json({ message: 'รหัสผ่านไม่ตรงกัน' });
    }

    try {
        const connection = await mysql.createConnection(dbConfig);
        const [existingUser] = await connection.execute(
            'SELECT * FROM users WHERE email = ? OR phone = ?',
            [email, phone]
        );

        if (existingUser.length > 0) {
            await connection.end();
            return res.status(400).json({ message: 'อีเมลหรือเบอร์โทรศัพท์นี้ถูกใช้งานแล้ว' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const [result] = await connection.execute(
            'INSERT INTO users (email, phone, password, role, is_active) VALUES (?, ?, ?, ?, ?)',
            [email, phone, hashedPassword, 'user', 0]
        );

        await connection.end();
        
        res.status(201).json({ 
            message: 'สมัครสมาชิกสำเร็จ', 
            userId: result.insertId 
        });

    } catch (error) {
        console.error('Register Error:', error);
        res.status(500).json({ message: 'เกิดข้อผิดพลาดในการสมัครสมาชิก', error: error.message });
    }
};

exports.login = async (req, res) => {
    const { loginIdentifier, password } = req.body; // loginIdentifier รับเป็น email หรือ phone ก็ได้

    if (!loginIdentifier || !password) {
        return res.status(400).json({ message: "กรุณากรอก Email/เบอร์โทร และรหัสผ่าน" });
    }

    try {
        const connection = await mysql.createConnection(dbConfig);

        // 1. ค้นหา User จาก Email หรือ Phone
        // เปลี่ยนชื่อคอลัมน์ให้ตรงกับ Database จริง (email, phone, is_active)
        const [rows] = await connection.execute(
            "SELECT * FROM users WHERE (email = ? OR phone = ?) AND is_active = 1",
            [loginIdentifier, loginIdentifier]
        );

        await connection.end();

        if (rows.length === 0) {
            return res.status(401).json({ message: "ไม่พบผู้ใช้ หรือบัญชียังไม่ถูกเปิดใช้งาน (Active)" });
        }

        const user = rows[0];

        // 2. ตรวจสอบรหัสผ่าน
        // เปลี่ยน user.PasswordHash เป็น user.password ตามชื่อคอลัมน์ใน DB
        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(401).json({ message: "รหัสผ่านไม่ถูกต้อง" });
        }

        // 3. สร้าง Token (JWT)
        // ใช้ process.env.JWT_SECRET ถ้าไม่มีให้ใช้คีย์สำรอง 'secret_key'
        const secretKey = process.env.JWT_SECRET || 'secret_key'; 
        const token = jwt.sign(
            {
                userId: user.id,      // ตรงกับ user.id ใน DB
                email: user.email,
                role: user.role
            }
            // secretKey,
            // { expiresIn: "8h" }
        );
        
        return res.status(200).json({ 
            message: "เข้าสู่ระบบสำเร็จ",
            token,
            user: {
                id: user.id,
                email: user.email,
                role: user.role
            }
        });

    } catch (err) {
        console.error('Login Error:', err);
        return res.status(500).json({ message: "เกิดข้อผิดพลาดในการเข้าสู่ระบบ" });
    }
};

exports.sendOtp = async (req, res) => {
    const { email } = req.body;
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 นาที

    try {
        const connection = await mysql.createConnection(dbConfig);

        // 1. หา User ID จาก Email
        const [users] = await connection.execute(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            await connection.end();
            return res.status(404).json({ message: 'ไม่พบอีเมลนี้ในระบบ' });
        }

        const userId = users[0].id;

        // 2. บันทึกลงตาราง user_otps
        await connection.execute(
            'INSERT INTO user_otps (user_id, otp_code, expires_at, is_used) VALUES (?, ?, ?, 0)',
            [userId, otp, expiresAt]
        );
        
        await connection.end();

        // 3. ส่ง Email
        await transporter.sendMail({
            from: 'Smile Dental Admin',
            to: email,
            subject: 'รหัส OTP ของคุณ',
            html: `รหัส OTP คือ: <b>${otp}</b> (หมดอายุใน 5 นาที)`
        });

        res.json({ message: 'ส่ง OTP แล้ว' });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'ส่ง OTP ไม่สำเร็จ', error: error.message });
    }
};

exports.verifyOtp = async (req, res) => {
    const { email, otp } = req.body;

    try {
        const connection = await mysql.createConnection(dbConfig);

        // 1. หา User ID จาก Email
        const [users] = await connection.execute(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            await connection.end();
            return res.status(404).json({ message: 'ไม่พบผู้ใช้งาน' });
        }

        const userId = users[0].id;

        // 2. ตรวจสอบ OTP ในตาราง user_otps
        const [rows] = await connection.execute(
            `SELECT * FROM user_otps 
             WHERE user_id = ? 
             AND otp_code = ? 
             AND is_used = 0 
             AND expires_at > NOW()`,
            [userId, otp]
        );

        if (rows.length > 0) {
            // 3. อัปเดต OTP ว่าใช้แล้ว
            await connection.execute(
                'UPDATE user_otps SET is_used = 1 WHERE id = ?', 
                [rows[0].id]
            );

            // 4. (สำคัญ) อัปเดตสถานะ User ให้ Active (ยืนยันตัวตนสำเร็จ)
            await connection.execute(
                'UPDATE users SET is_active = 1 WHERE id = ?',
                [userId]
            );

            await connection.end();
            res.json({ message: 'Verify สำเร็จ! บัญชีของคุณถูกเปิดใช้งานแล้ว' });
        } else {
            await connection.end();
            res.status(400).json({ message: 'รหัส OTP ไม่ถูกต้อง หรือหมดอายุแล้ว' });
        }

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error Verifying OTP' });
    }
};