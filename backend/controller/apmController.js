const pool = require('../config/db');

exports.bookAppointmentByUser = async (req, res) => {
    const connection = await pool.getConnection();

    try {
        const user_id = req.user.id; 
        const { appointment_date, appointment_time, reason, notes } = req.body;

        if (!appointment_date || !appointment_time) {
            connection.release(); 
            return res.status(400).json({ success: false, message: 'กรุณาระบุวันที่และเวลา' });
        }

        await connection.beginTransaction();

        const checkCapacitySql = `
            SELECT COUNT(id) as total_bookings 
            FROM appointments 
            WHERE appointment_date = ? AND appointment_time = ? AND status != 'cancelled'
            FOR UPDATE
        `;
        const [capacityResult] = await connection.execute(checkCapacitySql, [appointment_date, appointment_time]);
        
        if (capacityResult[0].total_bookings >= 4) {
            await connection.rollback(); 
            connection.release();
            return res.status(400).json({ success: false, message: 'คิวเวลานี้เต็มแล้ว กรุณาเลือกเวลาอื่น' });
        }

        const insertSql = `
            INSERT INTO appointments 
            (user_id, doctor_id, appointment_date, appointment_time, reason, notes) 
            VALUES (?, NULL, ?, ?, ?, ?)
        `;
        const [result] = await connection.execute(insertSql, [user_id, appointment_date, appointment_time, reason || null, notes || null]);

        await connection.commit();
        res.status(201).json({ success: true, message: 'จองคิวสำเร็จ', appointmentId: result.insertId });

    } catch (error) {
        await connection.rollback();
        console.error('User Booking Error:', error);
        res.status(500).json({ success: false, message: 'ไม่สามารถจองคิวได้' });
    } finally {
        if (connection) connection.release();
    }
};

exports.bookAppointmentByAdmin = async (req, res) => {
    const connection = await pool.getConnection();

    try {
        // 💡 รับค่า hn และ doctor_name มาจาก Flutter
        const { hn, doctor_name, appointment_date, appointment_time, reason, notes } = req.body;

        if (!hn || !appointment_date || !appointment_time) {
            connection.release();
            return res.status(400).json({ success: false, message: 'กรุณากรอกรหัสผู้ป่วย วันที่ และเวลาให้ครบ' });
        }

        await connection.beginTransaction();

        // 1. แปลง HN เป็น user_id
        const [users] = await connection.execute('SELECT user_id FROM user_profiles WHERE hn = ?', [hn]);
        if (users.length === 0) {
            await connection.rollback();
            connection.release();
            return res.status(404).json({ success: false, message: 'ไม่พบรหัสผู้ป่วยนี้ในระบบ' });
        }
        const user_id = users[0].user_id;

        // 2. เช็คโควตาคิว 4 คน
        const checkCapacitySql = `
            SELECT COUNT(id) as total_bookings 
            FROM appointments 
            WHERE appointment_date = ? AND appointment_time = ? AND status != 'cancelled'
            FOR UPDATE
        `;
        const [capacityResult] = await connection.execute(checkCapacitySql, [appointment_date, appointment_time]);
        
        if (capacityResult[0].total_bookings >= 4) {
            await connection.rollback();
            connection.release();
            return res.status(400).json({ success: false, message: 'คิวเวลานี้เต็มแล้ว (ครบ 4 คน)' });
        }

        // 3. บันทึกข้อมูลเข้าฐานข้อมูล
        const insertSql = `
            INSERT INTO appointments 
            (user_id, doctor_id, appointment_date, appointment_time, reason, notes, status) 
            VALUES (?, NULL, ?, ?, ?, ?, 'booking')
        `;
        const fullNotes = `แพทย์: ${doctor_name || '-'} | ${notes || ''}`;
        const [result] = await connection.execute(insertSql, [user_id, appointment_date, appointment_time, reason || null, fullNotes]);

        await connection.commit();
        res.status(201).json({ success: true, message: 'เพิ่มการนัดหมายสำเร็จ', appointmentId: result.insertId });

    } catch (error) {
        await connection.rollback();
        console.error('Admin Booking Error:', error);
        res.status(500).json({ success: false, message: 'ไม่สามารถเพิ่มการนัดหมายได้' });
    } finally {
        if (connection) connection.release();
    }
};

exports.getAvailableSlots = async (req, res) => {
    try {
        const { date } = req.query;

        if (!date) {
            return res.status(400).json({ success: false, message: 'กรุณาระบุวันที่' });
        }

        const sql = `
            SELECT appointment_time, COUNT(id) as booked_count 
            FROM appointments 
            WHERE appointment_date = ? 
              AND status != 'cancelled'
            GROUP BY appointment_time
        `;
        const [bookedSlots] = await pool.execute(sql, [date]);

        const allTimeSlots = [
            '09:00:00', '10:00:00', '11:00:00', '13:00:00', 
            '14:00:00', '15:00:00', '16:00:00', '17:00:00'
        ];

        const slotsStatus = allTimeSlots.map(time => {
            const foundSlot = bookedSlots.find(slot => slot.appointment_time === time);
            const currentBookings = foundSlot ? foundSlot.booked_count : 0;
            
            return {
                time: time,
                bookedCount: currentBookings,
                isFull: currentBookings >= 4 
            };
        });

        res.status(200).json({
            success: true,
            date: date,
            slots: slotsStatus
        });

    } catch (error) {
        console.error('Error fetching available slots:', error);
        res.status(500).json({ success: false, message: 'เกิดข้อผิดพลาดในการดึงข้อมูลคิว' });
    }
};

// 💡 เพิ่มฟังก์ชันสำหรับดึงตารางนัดหมายทั้งหมด
exports.getAllAppointments = async (req, res) => {
    try {
        const sql = `
            SELECT a.id as apt_id, a.appointment_date, a.appointment_time, a.status, a.reason, a.notes,
                   p.hn, p.title, p.first_name, p.last_name, u.phone
            FROM appointments a
            JOIN users u ON a.user_id = u.id
            JOIN user_profiles p ON u.id = p.user_id
            ORDER BY a.appointment_date DESC, a.appointment_time ASC
        `;
        const [rows] = await pool.execute(sql);
        res.status(200).json({ success: true, appointments: rows });
    } catch (error) {
        console.error('Error fetching all appointments:', error);
        res.status(500).json({ success: false, message: 'เกิดข้อผิดพลาดในการดึงข้อมูลตารางนัดหมาย' });
    }
};

// 💡 เพิ่มฟังก์ชันยกเลิกนัดหมาย
exports.cancelAppointment = async (req, res) => {
    try {
        const { id } = req.params;
        await pool.execute(`UPDATE appointments SET status = 'cancelled' WHERE id = ?`, [id]);
        res.status(200).json({ success: true, message: 'ยกเลิกการนัดหมายแล้ว' });
    } catch (error) {
        console.error('Error cancelling appointment:', error);
        res.status(500).json({ success: false, message: 'เกิดข้อผิดพลาดในการยกเลิกนัดหมาย' });
    }
};