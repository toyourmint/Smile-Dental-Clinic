const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

const mysql = require('mysql2/promise');
const nodemailer = require('nodemailer');

// let mockOtpDB = {};

// ================= DB CONNECTION (สำคัญที่สุด) =================
// async function getConnection() {
//   const connection = await mysql.createConnection(dbConfig);

//   // 🔥 บรรทัดนี้คือหัวใจของปัญหาภาษาไทย
//   await connection.query('SET NAMES utf8mb4');

//   return connection;
// }

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
        address_line, subdistrict, district, province, postal_code,
        rights: treatment_right,
        allergies, disease, medicine    // 👈 เพิ่มตรงนี้
    } = req.body;
    
    if (!email || !phone || !citizen_id || !first_name) {
        return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
    }

      // ✅ กันค่าว่างจาก Flutter
  const safeTitle = title && title.trim() !== '' ? title : null;

  const connection = await pool.getConnection();

    try {
        await connection.beginTransaction();

        // 1. check duplicate
        const [existing] = await connection.execute(
            'SELECT id FROM users WHERE email = ? OR phone = ?',
            [email, phone]
        );

        if (existing.length > 0) {
            await connection.rollback();
            return res.status(400).json({ message: 'Email หรือเบอร์โทรนี้ลงทะเบียนไปแล้ว' });
        }

        // 2. create user (password = PENDING)
        const [userResult] = await connection.execute(
            'INSERT INTO users (email, phone, password, role, is_active) VALUES (?, ?, ?, ?, ?)',
            [email, phone, 'PENDING', 'user', 0]
        );
        const userId = userResult.insertId;
        
        let annualBudget = 0;
        if (treatment_right === 'social_security') {
            annualBudget = 900;
        }

        // ==========================================
        // 🔥 GEN HN (SD-YYXXXX)
        // ==========================================
        const currentYear = new Date().getFullYear().toString().slice(-2); // ดึงปีปัจจุบัน (เช่น '26' จาก 2026)
        const hnPrefix = `SD-${currentYear}`;

        // ดึงเลข HN ล่าสุดของปีนี้ (ใช้ FOR UPDATE เพื่อป้องกันคนกดสมัครพร้อมกันแล้วได้เลขซ้ำ)
        const [lastHnResult] = await connection.execute(
            `SELECT hn FROM user_profiles WHERE hn LIKE ? ORDER BY hn DESC LIMIT 1 FOR UPDATE`,
            [`${hnPrefix}%`]
        );

        let nextNumber = 1; // เริ่มต้นที่ 1 ถ้ายังไม่มีข้อมูลในปีนั้น
        if (lastHnResult.length > 0 && lastHnResult[0].hn) {
            const lastHn = lastHnResult[0].hn; // เช่น 'SD-260001'
            // ตัดเอาเฉพาะ 4 ตัวท้ายมาแปลงเป็นตัวเลข แล้วบวก 1
            const lastNumber = parseInt(lastHn.slice(-4), 10);
            if (!isNaN(lastNumber)) {
                nextNumber = lastNumber + 1;
            }
        }

        // เติมเลขศูนย์ข้างหน้าให้ครบ 4 หลัก (เช่น 1 -> '0001')
        const paddedNumber = nextNumber.toString().padStart(4, '0');
        const generatedHn = `${hnPrefix}${paddedNumber}`; // จะได้ 'SD-260001'
        // ==========================================

        // 3. profile
        await connection.execute(
            `INSERT INTO user_profiles 
            (user_id, citizen_id, title, first_name, last_name, birth_date, gender, treatment_right, allergies, disease, medicine, annual_budget, hn)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [userId, citizen_id, safeTitle, first_name, last_name, birth_date, gender, treatment_right, allergies, disease, medicine, annualBudget, generatedHn]
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
        console.error(error);
        res.status(500).json({ message: 'เกิดข้อผิดพลาด' });
    } finally{
        connection.release();
    }
};

exports.addUserByAdmin = async (req, res) => {
    const {
        citizen_id, title, first_name, last_name, birth_date, gender,
        email, phone,
        address_line, subdistrict, district, province, postal_code,
        rights: treatment_right,
        allergies, disease, medicine
    } = req.body;

    // 1. Validation เบื้องต้น
    if (!citizen_id || !first_name || !last_name || !phone) {
        return res.status(400).json({ message: 'กรุณากรอกข้อมูลสำคัญให้ครบถ้วน' });
    }

    

    try {
        const connection = await pool.getConnection();
        await connection.beginTransaction();

        // 2. ตรวจสอบเบอร์โทรซ้ำ (ใช้ phone ที่รับมาตรงๆ)
        const [existing] = await connection.execute(
            'SELECT id FROM users WHERE phone = ?',
            [phone]
        );

        if (existing.length > 0) {
            await connection.rollback();
            return res.status(400).json({ message: 'เบอร์โทรศัพท์นี้มีในระบบแล้ว' });
        }

        // 3. Hash รหัสผ่านโดยใช้เบอร์โทรศัพท์เป็นต้นแบบ
        const hashedPassword = await bcrypt.hash(phone, 10);

        // 4. บันทึกลงตาราง users และเปิดใช้งานทันที
        const [userResult] = await connection.execute(
            'INSERT INTO users (email, phone, password, role, is_active) VALUES (?, ?, ?, ?, ?)',
            [email || null, phone, hashedPassword, 'user', 1]
        );
        const userId = userResult.insertId;

        // 5. จัดการ Logic เลข HN (SD-YYXXXX)
        const currentYear = new Date().getFullYear().toString().slice(-2);
        const hnPrefix = `SD-${currentYear}`;

        const [lastHnResult] = await connection.execute(
            `SELECT hn FROM user_profiles WHERE hn LIKE ? ORDER BY hn DESC LIMIT 1 FOR UPDATE`,
            [`${hnPrefix}%`]
        );

        let nextNumber = 1;
        if (lastHnResult.length > 0 && lastHnResult[0].hn) {
            const lastNumber = parseInt(lastHnResult[0].hn.slice(-4), 10);
            if (!isNaN(lastNumber)) nextNumber = lastNumber + 1;
        }
        const generatedHn = `${hnPrefix}${nextNumber.toString().padStart(4, '0')}`;

        // 6. บันทึก User Profile
        const safeTitle = title && title.trim() !== '' ? title : null;
        await connection.execute(
            `INSERT INTO user_profiles 
            (user_id, citizen_id, title, first_name, last_name, birth_date, gender, treatment_right, allergies, disease, medicine, annual_budget, hn)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [userId, citizen_id, safeTitle, first_name, last_name, birth_date, gender, treatment_right, allergies, disease, medicine, (treatment_right === 'social_security' ? 900 : 0), generatedHn]
        );

        // 7. บันทึก Address
        await connection.execute(
            `INSERT INTO user_addresses (user_id, address_line, subdistrict, district, province, postal_code)
            VALUES (?, ?, ?, ?, ?, ?)`,
            [userId, address_line, subdistrict, district, province, postal_code]
        );

        await connection.commit();

        res.status(201).json({ 
            message: 'เพิ่มข้อมูลผู้ป่วยสำเร็จ',
            hn: generatedHn,
            password_hint: 'รหัสผ่านเริ่มต้นคือเบอร์โทรศัพท์'
        });

    } catch (error) {
        await connection.rollback();
        console.error(error);
        res.status(500).json({ message: 'เกิดข้อผิดพลาดในการบันทึกข้อมูล' });
    } finally {
        connection.release();
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

        const [rows] = await pool.execute(
            'SELECT * FROM users WHERE (email = ? OR phone = ?) AND is_active = 1',
            [loginIdentifier, loginIdentifier]
        );

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
        const [users] = await pool.execute(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            return res.status(404).json({ message: 'ไม่พบอีเมลนี้ในระบบ' });
        }

        const userId = users[0].id;
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

        await pool.execute(
            'UPDATE user_otps SET is_used = 1 WHERE user_id = ?',
            [userId]
        );

        await pool.execute(
            'INSERT INTO user_otps (user_id, otp_code, expires_at, is_used) VALUES (?, ?, ?, 0)',
            [userId, otp, expiresAt]
        );

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
        const [users] = await pool.execute('SELECT id FROM users WHERE email = ?', [email]);
        if (users.length === 0) return res.status(404).json({ message: 'ไม่พบผู้ใช้' });

        const userId = users[0].id;

        const [rows] = await pool.execute(
            `SELECT id FROM user_otps WHERE user_id = ? AND otp_code = ? AND is_used = 0 AND expires_at > NOW()`,
            [userId, otp]
        );

        if (rows.length === 0) {
            return res.status(400).json({ message: 'OTP ไม่ถูกต้องหรือหมดอายุ' });
        }

        // 🔥 เพิ่มบรรทัดนี้: ต่ออายุ OTP นี้ออกไปอีก 10 นาที นับจากตอนที่กรอกถูก
        await pool.execute(
            `UPDATE user_otps SET expires_at = DATE_ADD(NOW(), INTERVAL 10 MINUTE) WHERE id = ?`,
            [rows[0].id]
        );

        res.json({ message: 'OTP ถูกต้องและได้ขยายเวลาสำหรับตั้งรหัสผ่านแล้ว' });

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
        const [users] = await pool.execute(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        const userId = users[0].id;

        const [otpRows] = await pool.execute(
            `SELECT id FROM user_otps
             WHERE user_id = ? AND otp_code = ? AND is_used = 0 AND expires_at > NOW()`,
            [userId, otp]
        );

        if (otpRows.length === 0) {
            return res.status(400).json({
                message: 'รหัส OTP ไม่ถูกต้องหรือหมดอายุ'
            });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        await pool.execute(
            'UPDATE users SET password = ?, is_active = 1 WHERE id = ?',
            [hashedPassword, userId]
        );

        await pool.execute(
            'UPDATE user_otps SET is_used = 1 WHERE id = ?',
            [otpRows[0].id]
        );

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
        const [users] = await pool.execute(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            return res.status(404).json({ message: 'ไม่พบผู้ใช้' });
        }

        const userId = users[0].id;

        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

        await pool.execute(
            'UPDATE user_otps SET is_used = 1 WHERE user_id = ? AND is_used = 0',
            [userId]
        );

        await pool.execute(
            'INSERT INTO user_otps (user_id, otp_code, expires_at, is_used) VALUES (?, ?, ?, 0)',
            [userId, otp, expiresAt]
        );

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
