const pool = require('../config/db');

exports.generateQueueNo = async (req, res) => {
    const { appointment_id, user_id, room } = req.body;
    
    const connection = await pool.getConnection(); // 💡 แก้จาก db เป็น pool
    await connection.beginTransaction();

    try {
        const [rows] = await connection.query(`
            SELECT COALESCE(MAX(queue_number), 0) AS max_queue 
            FROM queues 
            WHERE queue_date = CURDATE()
        `);
        const nextQueueNumber = rows[0].max_queue + 1; 

        await connection.query(`
            INSERT INTO queues (appointment_id, user_id, queue_number, queue_date, room, status) 
            VALUES (?, ?, ?, CURDATE(), ?, 'waiting')
        `, [appointment_id, user_id || 0, nextQueueNumber, room]);

        await connection.query(`
            UPDATE appointments 
            SET status = 'arrived' 
            WHERE id = ?
        `, [appointment_id]);

        await connection.commit(); 
        res.status(200).json({ message: "สร้างคิวสำเร็จ", queue_label: `${room}${nextQueueNumber}` });

    } catch (error) {
        await connection.rollback(); 
        console.log(error);
        res.status(500).json({ error: "เกิดข้อผิดพลาดในการสร้างคิว" });
    } finally {
        connection.release();
    }
};

exports.nextQueueNo = async (req, res) => {
    const { room } = req.query;
    try {
        await pool.query(`UPDATE queues SET status = 'done' WHERE room = ? AND status = 'in_room' AND queue_date = CURDATE()`, [room]);

        const [nextQueueRows] = await pool.query(`
            SELECT id, queue_number, user_id 
            FROM queues 
            WHERE room = ? AND status = 'waiting' AND queue_date = CURDATE()
            ORDER BY queue_number ASC LIMIT 1
        `, [room]);

        if (nextQueueRows.length === 0) return res.status(200).json({ message: "ไม่มีคิวรอแล้ว" });

        const nextQueue = nextQueueRows[0];
        await pool.query(`UPDATE queues SET status = 'in_room' WHERE id = ?`, [nextQueue.id]);

        const currentQueueLabel = `${room}${nextQueue.queue_number}`;
        
        // 💡 io.emit คอมเมนต์ไว้ก่อน (เผื่ออนาคตทำจอทีวีเรียกคิว)
        // if(global.io) io.emit('QUEUE_UPDATED', { room: room, current_queue: currentQueueLabel });

        res.status(200).json({ message: "เรียกคิวถัดไปสำเร็จ", called_queue: currentQueueLabel });
    } catch (error) {
        res.status(500).json({ error: "ระบบขัดข้อง" });
    }
};

exports.skipQueueNo = async (req, res) => {
    const { room } = req.query;
    try {
        await pool.query(`UPDATE queues SET status = 'skipped' WHERE room = ? AND status = 'in_room' AND queue_date = CURDATE()`, [room]);

        const [nextQueueRows] = await pool.query(`
            SELECT id, queue_number, user_id 
            FROM queues 
            WHERE room = ? AND status = 'waiting' AND queue_date = CURDATE()
            ORDER BY queue_number ASC LIMIT 1
        `, [room]);

        if (nextQueueRows.length === 0) return res.status(200).json({ message: "ข้ามคิวสำเร็จ แต่ไม่มีคิวรอแล้ว", called_queue: '-' });

        const nextQueue = nextQueueRows[0];
        await pool.query(`UPDATE queues SET status = 'in_room' WHERE id = ?`, [nextQueue.id]);

        res.status(200).json({ message: "ข้ามคิวสำเร็จ และเรียกคิวถัดไปเรียบร้อย", called_queue: `${room}${nextQueue.queue_number}` });
    } catch (error) {
        res.status(500).json({ error: "ระบบขัดข้องในการข้ามคิว" });
    }
};

exports.getRoomQueues = async (req, res) => {
    try {
        const [rows] = await pool.query(`SELECT room, queue_number FROM queues WHERE status = 'in_room' AND queue_date = CURDATE()`);
        let dashboardData = { current_A: '-', current_B: '-' };
        rows.forEach(row => {
            if (row.room === 'A') dashboardData.current_A = `A${row.queue_number}`;
            if (row.room === 'B') dashboardData.current_B = `B${row.queue_number}`;
        });
        res.status(200).json(dashboardData);
    } catch (error) {
        res.status(500).json({ error: "ดึงข้อมูลคิวไม่สำเร็จ" });
    }
};

exports.getAllQueues = async (req, res) => {
    const filterDate = req.query.date; 
    try {
        let sql = `
            SELECT 
                a.id AS appointment_id,
                u.user_id, -- 💡 เพิ่มเพื่อส่งไปสร้างคิวได้
                u.first_name, 
                u.last_name, 
                p.phone,
                a.appointment_date, 
                a.appointment_time, 
                a.reason AS treatment,
                d.doctor_name AS doctor_name,
                q.queue_number, 
                q.room AS assigned_room, 
                CASE 
                    WHEN a.status = 'cancelled' THEN 'Cancelled'
                    WHEN q.status = 'waiting' THEN 'Waiting'
                    WHEN q.status = 'in_room' THEN 'InQueue'
                    WHEN q.status = 'done' THEN 'Done'
                    WHEN q.status = 'skipped' THEN 'Skipped'
                    ELSE 'Confirmed' 
                END AS current_status
            FROM appointments a
            JOIN user_profiles u ON a.user_id = u.user_id
            LEFT JOIN users p ON a.user_id = p.id
            LEFT JOIN doctors d ON a.doctor_id = d.id
            LEFT JOIN queues q ON a.id = q.appointment_id
        `;

        const queryParams = [];
        if (filterDate) {
            sql += ` WHERE a.appointment_date = ?`;
            queryParams.push(filterDate);
        } else {
            sql += ` WHERE a.appointment_date = CURDATE()`;
        }
        sql += ` ORDER BY a.appointment_time ASC`;

        const [rows] = await pool.execute(sql, queryParams);
        res.status(200).json({ profiles: rows });
    } catch (error) {
        console.error('Error fetching queues:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};