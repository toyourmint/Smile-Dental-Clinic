const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

// exports.register = async (req, res) => {
//     const { username, password } = req.body;
//     try {
//         const hashedPassword = await bcrypt.hash(password, 10);
//         const newUser = await pool.query(
//             'INSERT INTO users (username, password) VALUES ($1, $2) RETURNING *',
//             [username, hashedPassword]
//         );
//         res.status(201).json({ message: 'User registered successfully', user: newUser.rows[0] });
//     } catch (error) {
//         res.status(500).json({ error: 'Internal server error' });
//     }
// };

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