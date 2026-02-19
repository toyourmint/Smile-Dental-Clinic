var jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
        return res.status(401).send('Authorization header missing');
    }

    const token = authHeader.split(' ')[1];
    try {
        // ใช้ fallback 'secret_key' ให้ตรงกับตอน sign ใน authController
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret_key');
        
        // แมปค่าใส่ req.user (แปลง userId เป็น id เพื่อให้ Controller เอาไปใช้ได้เลย)
        req.user = {
            id: decoded.userId,
            email: decoded.email,
            role: decoded.role
        };
        
        next();
    } catch (err) {
        return res.status(401).send('Invalid token');
    }
}

module.exports = authMiddleware;