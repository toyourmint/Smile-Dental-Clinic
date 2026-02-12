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
        FROM 
            user_profile p
        LEFT JOIN 
            user u ON p.citizen_id = u.citizen_id
        `;

        const [rows] = await pool.execute(sql);
        res.status(200).json({ profiles: rows });
    } catch (error) {
        console.error('Error fetching user profiles:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};
        