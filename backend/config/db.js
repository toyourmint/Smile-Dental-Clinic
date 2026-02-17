require('dotenv').config();
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT || 3306,
    // charset: process.env.DB_CHARSET,
    charset: 'utf8mb4_unicode_ci',   // ⭐ เปลี่ยนแบบนี้
    waitForConnections: true,
    connectionLimit: 10,     // รองรับ 10 connection พร้อมกัน
    queueLimit: 0
});
//pool.query("SET NAMES utf8mb4");

module.exports = pool;

// const dbConfig = {
//     host: 'db',
//     port: 3306,
//     user: 'root',
//     password: 'root',
//     database: 'clinic_db',
//     charset: 'utf8mb4'
// };

// const mysql = require('mysql2');
// require('dotenv').config();

// const pool = mysql.createPool({
//   host: process.env.DB_HOST,
//   user: process.env.DB_USER,
//   password: process.env.DB_PASS,
//   database: process.env.DB_NAME,
//   charset: 'utf8mb4'
// });

// pool.query("SET NAMES utf8mb4");

// module.exports = pool.promise();
