const pool = require('../config/db');

exports.getUserProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    if (!userId) {
      return res.status(400).json({ message: 'Missing user id' });
    }

    const sql = `
      SELECT 
        p.hn,
        p.gender,
        p.title,
        p.first_name,
        p.last_name,
        p.birth_date,
        u.phone,
        u.email,
        u.role,
        p.allergies,
        p.disease,
        p.medicine,
        p.treatment_right,
        p.annual_budget,
        a.address_line,
        a.subdistrict,
        a.district,
        a.province,
        a.postal_code
      FROM users u
      LEFT JOIN user_profiles p ON u.id = p.user_id
      LEFT JOIN user_addresses a ON u.id = a.user_id
      WHERE u.id = ?
    `;

    const [rows] = await pool.execute(sql, [userId]);

    if (rows.length === 0) {
      return res.status(404).json({ message: 'ไม่พบข้อมูลผู้ใช้' });
    }

    res.json(rows[0]);

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

exports.getAllUserProfiles = async (req, res) => {
    try {
        const sql = `
        SELECT 
            p.hn AS hn,                 
            p.gender AS gender,
            p.citizen_id AS citizen_id,
            p.title AS title, 
            p.first_name AS first_name, 
            p.last_name AS last_name, 
            p.birth_date AS birth_date,
            u.phone AS phone,
            u.email AS email,
            u.role AS role,
            p.allergies AS allergies,
            p.disease AS disease,
            p.medicine AS medicine,
            p.treatment_right AS treatment_right,
            p.annual_budget AS annual_budget,
            a.address_line AS address_line,
            a.subdistrict AS subdistrict,
            a.district AS district,
            a.province AS province,
            a.postal_code AS postal_code
        FROM 
            users u
        LEFT JOIN 
            user_profiles p ON u.id = p.user_id
        LEFT JOIN 
            user_addresses a ON u.id = a.user_id
        WHERE 
            u.role = 'user'
        `;

        const [rows] = await pool.execute(sql);
        res.status(200).json({ profiles: rows });
    } catch (error) {
        console.error('Error fetching user profiles:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

exports.editUserProfile = async (req, res) => {
  // ดึง connection ออกมาจาก pool เพื่อทำ Transaction
  const connection = await pool.getConnection();

  try {
    // รับข้อมูล id จาก params, query หรือ body (ในตัวอย่างนี้ใช้ body)
    const {
      id, // จำเป็นต้องมีเพื่อระบุตัวผู้ใช้
      
      // ข้อมูลจากตาราง users
      phone, email,
      
      // ข้อมูลจากตาราง user_profiles
      hn, gender, citizen_id, title, first_name, last_name, birth_date, 
      allergies, disease, medicine, treatment_right, annual_budget,
      
      // ข้อมูลจากตาราง user_addresses
      address_line, subdistrict, district, province, postal_code
    } = req.body;

    if (!id) {
      return res.status(400).json({ message: 'Missing user id' });
    }

    // เริ่มต้น Transaction
    await connection.beginTransaction();

    // 1. อัปเดตข้อมูลในตาราง users
    const updateUsersSql = `
      UPDATE users 
      SET phone = ?, email = ? 
      WHERE id = ?
    `;
    await connection.execute(updateUsersSql, [phone, email, id]);

    // 2. อัปเดตข้อมูลในตาราง user_profiles
    const updateProfilesSql = `
      UPDATE user_profiles 
      SET hn = ?, gender = ?, citizen_id = ?, title = ?, first_name = ?, 
          last_name = ?, birth_date = ?, allergies = ?, disease = ?, 
          medicine = ?, treatment_right = ?, annual_budget = ?
      WHERE user_id = ?
    `;
    await connection.execute(updateProfilesSql, [
      hn, gender, citizen_id, title, first_name, last_name, birth_date, 
      allergies, disease, medicine, treatment_right, annual_budget, id
    ]);

    // 3. อัปเดตข้อมูลในตาราง user_addresses
    const updateAddressesSql = `
      UPDATE user_addresses 
      SET address_line = ?, subdistrict = ?, district = ?, province = ?, postal_code = ?
      WHERE user_id = ?
    `;
    await connection.execute(updateAddressesSql, [
      address_line, subdistrict, district, province, postal_code, id
    ]);

    // หากคำสั่ง SQL ทั้งหมดทำงานสำเร็จ ให้ยืนยันการบันทึกข้อมูล (Commit)
    await connection.commit();

    res.status(200).json({ message: 'อัปเดตข้อมูลผู้ใช้งานสำเร็จ' });

  } catch (error) {
    // หากเกิด Error ระหว่างทาง ให้ยกเลิกการเปลี่ยนแปลงทั้งหมด (Rollback)
    await connection.rollback();
    console.error('Error updating user profile:', error);
    res.status(500).json({ message: 'Internal server error' });
  } finally {
    // คืน connection กลับเข้า pool เสมอไม่ว่าจะสำเร็จหรือล้มเหลว
    if (connection) {
      connection.release();
    }
  }
};

exports.getDoctorProfile = async (req, res) => {
    try {
        const sql = `
        SELECT 
            doctor_id,
            doctor_name
        FROM doctors
        `;

        const [rows] = await pool.execute(sql);
        res.status(200).json({ doctors: rows });
    } catch (error) {
        console.error('Error fetching doctor profiles:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};