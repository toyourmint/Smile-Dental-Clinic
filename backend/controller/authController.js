const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
//const pool = require('../config/db');

const mysql = require('mysql2/promise');
const nodemailer = require('nodemailer');

// let mockOtpDB = {};

// --- ตั้งค่า Database และ Email (ควรแยกไฟล์ Config แต่ใส่ตรงนี้ก่อนได้ครับ) ---
const dbConfig = {
    host: 'localhost',
    port: 3307,
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

    console.log("สิ่งที่ Postman ส่งมา:", req.body);
    const { 
        citizen_id, title, first_name, last_name, birth_date, gender, // Profile
        email, phone, // User
        address_line, subdistrict, district, province, postal_code // Address
    } = req.body;

    // ตรวจสอบข้อมูลจำเป็น
    if (!email || !phone || !citizen_id || !first_name) {
        return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
    }

    const connection = await mysql.createConnection(dbConfig);
    
    try {
        await connection.beginTransaction(); // เริ่ม Transaction (เพื่อให้บันทึกทุกตารางพร้อมกัน)

        // 1. เช็คว่ามี User ซ้ำไหม
        const [existing] = await connection.execute(
            'SELECT * FROM users WHERE email = ? OR phone = ?', [email, phone]
        );
        if (existing.length > 0) {
            await connection.rollback();
            return res.status(400).json({ message: 'Email หรือเบอร์โทรนี้ลงทะเบียนไปแล้ว' });
        }

        // 2. สร้าง User (ตั้งรหัสผ่านชั่วคราว PENDING, is_active = 0)
        const [userResult] = await connection.execute(
            'INSERT INTO users (email, phone, password, role, is_active) VALUES (?, ?, ?, ?, ?)',
            [email, phone, 'PENDING', 'user', 0]
        );
        const userId = userResult.insertId;

        // 3. บันทึก Profile
        await connection.execute(
            `INSERT INTO user_profiles (user_id, citizen_id, title, first_name, last_name, birth_date, gender) 
             VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [userId, citizen_id, title, first_name, last_name, birth_date, gender]
        );

        // 4. บันทึก Address
        await connection.execute(
            `INSERT INTO user_addresses (user_id, address_line, subdistrict, district, province, postal_code) 
             VALUES (?, ?, ?, ?, ?, ?)`,
            [userId, address_line, subdistrict, district, province, postal_code]
        );

        // 5. สร้าง OTP และบันทึก
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 นาที

        await connection.execute(
            'INSERT INTO user_otps (user_id, otp_code, expires_at, is_used) VALUES (?, ?, ?, 0)',
            [userId, otp, expiresAt]
        );

        await connection.commit(); // ยืนยันการบันทึกข้อมูลทั้งหมด
        await connection.end();

        // 6. ส่ง Email
        await transporter.sendMail({
            from: 'Smile Dental Admin',
            to: email,
            subject: 'รหัส OTP สำหรับลงทะเบียน',
            html: `รหัส OTP คือ: <b>${otp}</b>`
        });

        res.json({ message: 'บันทึกข้อมูลและส่ง OTP เรียบร้อยแล้ว' });

    } catch (error) {
        await connection.rollback(); // ถ้าพัง ให้ยกเลิกการบันทึกทั้งหมด
        await connection.end();
        console.error('Register Step 1 Error:', error);
        res.status(500).json({ message: 'เกิดข้อผิดพลาด', error: error.message });
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
        // const isMatch = await bcrypt.compare(password, user.PasswordHash || user.password);

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
            },
            secretKey,
            { expiresIn: "8h" }
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
//     const { email } = req.body;
//     const otp = Math.floor(100000 + Math.random() * 900000).toString();
//     const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 นาที

//     try {
//         const connection = await mysql.createConnection(dbConfig);

//         // 1. หา User ID จาก Email
//         const [users] = await connection.execute(
//             'SELECT id FROM users WHERE email = ?',
//             [email]
//         );

//         if (users.length === 0) {
//             await connection.end();
//             return res.status(404).json({ message: 'ไม่พบอีเมลนี้ในระบบ' });
//         }

//         const userId = users[0].id;

//         // 2. บันทึกลงตาราง user_otps
//         await connection.execute(
//             'INSERT INTO user_otps (user_id, otp_code, expires_at, is_used) VALUES (?, ?, ?, 0)',
//             [userId, otp, expiresAt]
//         );
        
//         await connection.end();

//         // 3. ส่ง Email
//         await transporter.sendMail({
//             from: 'Smile Dental Admin',
//             to: email,
//             subject: 'รหัส OTP ของคุณ',
//             html: `รหัส OTP คือ: <b>${otp}</b> (หมดอายุใน 5 นาที)`
//         });

//         res.json({ message: 'ส่ง OTP แล้ว' });

//     } catch (error) {
//         console.error(error);
//         res.status(500).json({ message: 'ส่ง OTP ไม่สำเร็จ', error: error.message });
//     }
// };

exports.verifyOtp = async (req, res) => {
    const { email, otp } = req.body;

    try {
        const connection = await mysql.createConnection(dbConfig);
        
        // หา User ID
        const [users] = await connection.execute('SELECT id FROM users WHERE email = ?', [email]);
        if (users.length === 0) {
            await connection.end();
            return res.status(404).json({ message: 'ไม่พบผู้ใช้' });
        }
        const userId = users[0].id;

        // เช็ค OTP
        const [rows] = await connection.execute(
            `SELECT * FROM user_otps WHERE user_id = ? AND otp_code = ? AND is_used = 0 AND expires_at > NOW()`,
            [userId, otp]
        );
        await connection.end();

        if (rows.length > 0) {
            // OTP ถูกต้อง -> ส่งกลับไปบอก Frontend ว่า "ผ่าน" ให้ไปหน้า 3 ได้
            res.json({ message: 'OTP ถูกต้อง', userId: userId });
        } else {
            res.status(400).json({ message: 'รหัส OTP ไม่ถูกต้องหรือหมดอายุ' });
        }

    } catch (error) {
        res.status(500).json({ message: 'Error checking OTP' });
    }
};

// --- ฟังก์ชันสำหรับปุ่ม "ส่งรหัสอีกครั้ง" (Resend OTP) ---
exports.resendOtp = async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'กรุณาระบุ Email' });
    }

    try {
        const connection = await mysql.createConnection(dbConfig);

        // 1. เช็คว่ามี User นี้ไหม
        const [users] = await connection.execute('SELECT id FROM users WHERE email = ?', [email]);
        if (users.length === 0) {
            await connection.end();
            return res.status(404).json({ message: 'ไม่พบข้อมูลในระบบ' });
        }
        const userId = users[0].id;

        // 2. สร้าง OTP ใหม่
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 นาที

        // 3. ยกเลิก OTP เก่าทั้งหมดก่อน (Optional: เพื่อความชัวร์ว่าจะมี OTP เดียวที่ใช้ได้)
        await connection.execute(
            'UPDATE user_otps SET is_used = 1 WHERE user_id = ? AND is_used = 0',
            [userId]
        );

        // 4. บันทึก OTP ใหม่
        await connection.execute(
            'INSERT INTO user_otps (user_id, otp_code, expires_at, is_used) VALUES (?, ?, ?, 0)',
            [userId, otp, expiresAt]
        );

        await connection.end();

        // 5. ส่ง Email ใหม่
        await transporter.sendMail({
            from: 'Smile Dental Admin',
            to: email,
            subject: 'รหัส OTP ใหม่ของคุณ (Resend)',
            html: `รหัส OTP ใหม่คือ: <b>${otp}</b> (หมดอายุใน 5 นาที)`
        });

        res.json({ message: 'ส่งรหัส OTP ใหม่เรียบร้อยแล้ว' });

    } catch (error) {
        console.error('Resend OTP Error:', error);
        res.status(500).json({ message: 'ส่ง OTP ไม่สำเร็จ' });
    }
};

exports.setPassword = async (req, res) => {
    const { email, password, confirmPassword, otp } = req.body;

    if (password !== confirmPassword) {
        return res.status(400).json({ message: 'รหัสผ่านไม่ตรงกัน' });
    }

    try {
        const connection = await mysql.createConnection(dbConfig);

        // 1. หา User
        const [users] = await connection.execute('SELECT id FROM users WHERE email = ?', [email]);
        if (users.length === 0) {
            await connection.end();
            return res.status(404).json({ message: 'User not found' });
        }
        const userId = users[0].id;

        // --- 🔴 2. (สำคัญมาก) ต้องเช็ค OTP ก่อน! ห้ามข้าม ---
        const [otpRows] = await connection.execute(
            `SELECT * FROM user_otps 
             WHERE user_id = ? AND otp_code = ? AND is_used = 0 AND expires_at > NOW()`,
            [userId, otp] // เอา otp ที่แอบส่งมา มาเช็คเทียบกับใน Database
        );

        if (otpRows.length === 0) {
            await connection.end();
            return res.status(400).json({ message: 'รหัส OTP ไม่ถูกต้อง หรือหมดอายุ (กรุณาทำรายการใหม่)' });
        }
        // -----------------------------------------------------

        // 3. เข้ารหัส Password
        const hashedPassword = await bcrypt.hash(password, 10);

        // 4. อัปเดต User (เปลี่ยนรหัสผ่านจริง)
        await connection.execute(
            'UPDATE users SET password = ?, is_active = 1 WHERE id = ?',
            [hashedPassword, userId]
        );

        // 5. Mark OTP as used (ใช้แล้วทิ้ง)
        await connection.execute('UPDATE user_otps SET is_used = 1 WHERE id = ?', [otpRows[0].id]);

        await connection.end();
        res.json({ message: 'ลงทะเบียนเสร็จสมบูรณ์! เข้าสู่ระบบได้เลย' });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error setting password' });
    }
};