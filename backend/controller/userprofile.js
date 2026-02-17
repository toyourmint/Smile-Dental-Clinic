const pool = require('../config/db');

exports.getUserProfile = async (req, res) => {
  try {
    const userId = req.query.id;

    if (!userId) {
      return res.status(400).json({ message: 'Missing user id' });
    }

    const sql = `
      SELECT 
        p.citizen_id,
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
