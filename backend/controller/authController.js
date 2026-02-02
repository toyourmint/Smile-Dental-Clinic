const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
//const pool = require('../config/db');

const mysql = require('mysql2/promise');
const nodemailer = require('nodemailer');

// --- ตั้งค่า Database และ Email (ควรแยกไฟล์ Config แต่ใส่ตรงนี้ก่อนได้ครับ) ---
const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'smile_dental_db' // เปลี่ยนเป็นชื่อ DB ของคุณ
};

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: '67010253@kmitl.ac.th', // อีเมลคุณ
        pass: 'xxxx xxxx xxxx xxxx'   // App Password
    }
});

exports.register = async (req, res) => {
    const { username, password } = req.body;
    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        const newUser = await pool.query(
            'INSERT INTO users (username, password) VALUES ($1, $2) RETURNING *',
            [username, hashedPassword]
        );
        res.status(201).json({ message: 'User registered successfully', user: newUser.rows[0] });
    } catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
};

exports.login = async (req, res) => {
    const { tel, password } = req.body;

    if (!tel || !password) {
        return res.status(400).json({ error: "Missing fields" });
    }

    try {
        const [rows] = await pool.query(
            "SELECT * FROM users WHERE Tel = ? AND IsActive = 1",
            [tel]
        );

        if (rows.length === 0) {
            return res.status(401).json({ error: "Invalid tel or password" });
        }

        const user = rows[0];
        const ok = await bcrypt.compare(password, user.PasswordHash);

        if (!ok) {
            return res.status(401).json({ error: "Invalid tel or password" });
        }

        const token = jwt.sign(
            {
                userId: user.UserID,
                username: user.Username,
                role: user.Role
            },
            process.env.JWT_SECRET,
            { expiresIn: "8h" }
        );
        
        return res.status(200).json({ message: "Login successful",
            token,
            username: user.Username,
            role: user.Role
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: "DB error" });
    }
};

exports.sendOtp = async (req, res) => {
    const { email } = req.body;
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 นาที

    try {
        const connection = await mysql.createConnection(dbConfig);
        await connection.execute(
            'INSERT INTO otps (email, otp_code, expires_at) VALUES (?, ?, ?)',
            [email, otp, expiresAt]
        );
        await connection.end();

        await transporter.sendMail({
            from: 'Smile Dental Admin',
            to: email,
            subject: 'รหัส OTP ของคุณ',
            html: `รหัส OTP คือ: <b>${otp}</b> (หมดอายุใน 5 นาที)`
        });

        res.json({ message: 'ส่ง OTP แล้ว' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'ส่ง OTP ไม่สำเร็จ' });
    }
};

exports.verifyOtp = async (req, res) => {
    const { email, otp } = req.body;

    try {
        const connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute(
            'SELECT * FROM otps WHERE email = ? AND otp_code = ? AND is_used = 0 AND expires_at > NOW()',
            [email, otp]
        );

        if (rows.length > 0) {
            await connection.execute('UPDATE otps SET is_used = 1 WHERE id = ?', [rows[0].id]);
            await connection.end();
            res.json({ message: 'Verify สำเร็จ!' });
        } else {
            await connection.end();
            res.status(400).json({ message: 'รหัสผิดหรือหมดอายุ' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error' });
    }
};