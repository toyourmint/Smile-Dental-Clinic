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
            u.id AS user_id,
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
  const connection = await pool.getConnection();

  try {
    const id = req.params.id;

    const {
      phone, email,
      hn, gender, citizen_id, title, first_name, last_name, birth_date,
      allergies, disease, medicine, treatment_right, annual_budget,
      address_line, subdistrict, district, province, postal_code
    } = req.body;

    if (!id) {
      return res.status(400).json({ message: 'Missing user id' });
    }

    await connection.beginTransaction();

    // 1. อัปเดตตาราง users
    await connection.execute(
      `UPDATE users SET phone = ?, email = ? WHERE id = ?`,
      [phone ?? null, email ?? null, id]
    );

    // 2. อัปเดตตาราง user_profiles
    await connection.execute(
      `UPDATE user_profiles 
       SET hn = ?, gender = ?, citizen_id = ?, title = ?, first_name = ?, 
           last_name = ?, birth_date = ?, allergies = ?, disease = ?, 
           medicine = ?, treatment_right = ?, annual_budget = ?
       WHERE user_id = ?`,
      [
        hn ?? null, gender ?? null, citizen_id ?? null, title ?? null,
        first_name ?? null, last_name ?? null, birth_date ?? null,
        allergies ?? null, disease ?? null, medicine ?? null,
        treatment_right ?? null, annual_budget ?? null, id
      ]
    );

    // 3. อัปเดตตาราง user_addresses
    await connection.execute(
      `UPDATE user_addresses 
       SET address_line = ?, subdistrict = ?, district = ?, province = ?, postal_code = ?
       WHERE user_id = ?`,
      [
        address_line ?? null, subdistrict ?? null, district ?? null,
        province ?? null, postal_code ?? null, id
      ]
    );

    await connection.commit();
    res.status(200).json({ message: 'อัปเดตข้อมูลผู้ใช้งานสำเร็จ' });

  } catch (error) {
    await connection.rollback();
    console.error('Error updating user profile:', error);
    res.status(500).json({ message: 'Internal server error' });
  } finally {
    if (connection) connection.release();
  }
};

exports.getDoctorProfile = async (req, res) => {
    try {
        const sql = `
        SELECT 
            id,
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