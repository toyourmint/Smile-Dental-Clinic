const pool = require('../config/db');

exports.getUserProfile = async (req, res) => {
    try {
        const sql = `
        SELECT 
            p.citizen_id AS citizen_id,
            p.title AS title, 
            p.first_name AS first_name, 
            p.last_name AS last_name, 
            p.birth_date AS birth_date,
            u.phone AS phone,
            u.email AS email,
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
        `;

        const [rows] = await pool.execute(sql);
        res.status(200).json({ profiles: rows });
    } catch (error) {
        console.error('Error fetching user profiles:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};
        