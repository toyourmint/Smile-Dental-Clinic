const pool = require('../config/db');

exports.generateQueueNo = async (req, res) => {
    const { appointment_id, user_id, room } = req.body;
    
    // เริ่ม Transaction เพื่อป้องกันข้อมูลพังถ้ามี error ระหว่างทาง
    const connection = await db.getConnection();
    await connection.beginTransaction();

    try {
        // 1. หาเลขคิวสูงสุดของวันนี้
        const [rows] = await connection.query(`
            SELECT COALESCE(MAX(queue_number), 0) AS max_queue 
            FROM queues 
            WHERE queue_date = CURDATE()
        `);
        const nextQueueNumber = rows[0].max_queue + 1; // บวก 1 เป็นคิวใหม่

        // 2. สร้างคิวใหม่ลงตาราง queues
        await connection.query(`
            INSERT INTO queues (appointment_id, user_id, queue_number, queue_date, room, status) 
            VALUES (?, ?, ?, CURDATE(), ?, 'waiting')
        `, [appointment_id, user_id, nextQueueNumber, room]);

        // 3. อัปเดตสถานะนัดหมายเป็น 'arrived' (มาถึงแล้ว)
        await connection.query(`
            UPDATE appointments 
            SET status = 'arrived' 
            WHERE id = ?
        `, [appointment_id]);

        await connection.commit(); // ยืนยันการบันทึกข้อมูล
        
        // ส่งเลขคิวกลับไปโชว์พนักงาน เช่น "A127"
        res.status(200).json({ 
            message: "สร้างคิวสำเร็จ", 
            queue_label: `${room}${nextQueueNumber}` 
        });

    } catch (error) {
        await connection.rollback(); // ยกเลิกถ้าพัง
        res.status(500).json({ error: "เกิดข้อผิดพลาดในการสร้างคิว" });
    } finally {
        connection.release();
    }
};

exports.nextQueueNo = async (req, res) => {
    const { room } = req.query;
    try {
        // 1. เปลี่ยนคิวปัจจุบัน (in_room) ของห้องนั้น ให้เป็น เสร็จสิ้น (done)
        await db.query(`
            UPDATE queues 
            SET status = 'done' 
            WHERE room = ? AND status = 'in_room' AND queue_date = CURDATE()
        `, [room]);

        // 2. ค้นหาคิวที่รออยู่ (waiting) ของห้องนั้น ที่คิวน้อยที่สุด (คิวถัดไป)
        const [nextQueueRows] = await db.query(`
            SELECT id, queue_number, user_id 
            FROM queues 
            WHERE room = ? AND status = 'waiting' AND queue_date = CURDATE()
            ORDER BY queue_number ASC 
            LIMIT 1
        `, [room]);

        if (nextQueueRows.length === 0) {
            return res.status(200).json({ message: "ไม่มีคิวรอแล้ว" });
        }

        const nextQueue = nextQueueRows[0];

        // 3. อัปเดตคิวถัดไปให้เป็น กำลังตรวจ (in_room)
        await db.query(`
            UPDATE queues 
            SET status = 'in_room' 
            WHERE id = ?
        `, [nextQueue.id]);

        // 4. (สำคัญมาก) ส่งสัญญาณ WebSocket ไปอัปเดตหน้าจอแอปและ Dashboard
        const currentQueueLabel = `${room}${nextQueue.queue_number}`;
        
        // io.emit จะส่งข้อมูลไปยังทุกเครื่องที่ต่อเน็ตคลินิกอยู่
        io.emit('QUEUE_UPDATED', {
            room: room,
            current_queue: currentQueueLabel // เช่น 'A128'
        });

        res.status(200).json({ 
            message: "เรียกคิวถัดไปสำเร็จ", 
            called_queue: currentQueueLabel 
        });

    } catch (error) {
        res.status(500).json({ error: "ระบบขัดข้อง" });
    }
};

exports.getRoomQueues = async (req, res) => {
    try {
        // ดึงคิวที่กำลังตรวจ (in_room) ของวันนี้ แยกตามห้อง
        const [rows] = await db.query(`
            SELECT room, queue_number 
            FROM queues 
            WHERE status = 'in_room' AND queue_date = CURDATE()
        `);

        // จัดรูปแบบให้อ่านง่าย เพื่อส่งให้ Frontend
        let dashboardData = {
            current_A: '-',
            current_B: '-'
        };

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
    // สมมติว่ารับวันที่มาจาก Frontend (เพื่อทำปุ่ม Filter by Date)
    // ถ้าไม่ส่งมา (เช่น เปิดหน้าแรก) ให้ใช้วันที่ปัจจุบัน
    const filterDate = req.query.date; 

    try {
        let sql = `
            SELECT 
                a.id AS appointment_id,
                u.first_name, 
                u.last_name, 
                u.phone,
                a.appointment_date, 
                a.appointment_time, 
                a.reason AS treatment,
                d.name AS doctor_name,
                q.queue_number, 
                q.room AS assigned_room, 
                
                -- 💡 รวมสถานะให้ฝั่งแอป Flutter เอาไปใช้ทำสีปุ่มได้เลย
                CASE 
                    WHEN a.status = 'cancelled' THEN 'Cancelled'
                    WHEN q.status = 'waiting' THEN 'Waiting'
                    WHEN q.status = 'in_room' THEN 'InQueue'
                    WHEN q.status = 'done' THEN 'Done'
                    ELSE 'Confirmed' 
                END AS current_status

            FROM appointments a
            JOIN user_profiles u ON a.user_id = u.user_id
            JOIN doctors d ON a.doctor_id = d.id
            LEFT JOIN queues q ON a.id = q.appointment_id
        `;

        const queryParams = [];

        // 💡 กรองข้อมูลตามวันที่ (สำคัญมาก)
        if (filterDate) {
            sql += ` WHERE a.appointment_date = ?`;
            queryParams.push(filterDate);
        } else {
            sql += ` WHERE a.appointment_date = CURDATE()`;
        }

        // 💡 เรียงลำดับเวลานัดจากเช้าไปเย็น
        sql += ` ORDER BY a.appointment_time ASC`;

        const [rows] = await pool.execute(sql, queryParams);
        
        // ส่งกลับไปให้ Flutter
        res.status(200).json({ profiles: rows });
        
    } catch (error) {
        console.error('Error fetching user profiles:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};