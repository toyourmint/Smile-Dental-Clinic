const pool = require('../config/db');

exports.bookAppointmentByUser = async (req, res) => {
    // 1. ดึง Connection ออกมาจาก Pool เพื่อเริ่ม Transaction
    const connection = await pool.getConnection();

    try {
        const user_id = req.user.id; 
        const { appointment_date, appointment_time, reason, notes } = req.body;

        if (!appointment_date || !appointment_time) {
            // ไม่ต้อง rollback เพราะยังไม่ได้เริ่ม transaction แต่ต้องคืน connection
            connection.release(); 
            return res.status(400).json({ success: false, message: 'กรุณาระบุวันที่และเวลา' });
        }

        // 2. เริ่มต้น Transaction
        await connection.beginTransaction();

        // 3. เช็คโควตา พร้อมล็อคข้อมูลชั่วคราว (FOR UPDATE)
        const checkCapacitySql = `
            SELECT COUNT(id) as total_bookings 
            FROM appointments 
            WHERE appointment_date = ? AND appointment_time = ? AND status != 'cancelled'
            FOR UPDATE
        `;
        const [capacityResult] = await connection.execute(checkCapacitySql, [appointment_date, appointment_time]);
        
        // โควตา 4 คนต่อช่วงเวลา
        if (capacityResult[0].total_bookings >= 4) {
            await connection.rollback(); // คิวเต็ม ให้ยกเลิกการทำงานทั้งหมด
            connection.release();
            return res.status(400).json({ success: false, message: 'คิวเวลานี้เต็มแล้ว กรุณาเลือกเวลาอื่น' });
        }

        // 4. บันทึกข้อมูล
        const insertSql = `
            INSERT INTO appointments 
            (user_id, doctor_id, appointment_date, appointment_time, reason, notes) 
            VALUES (?, NULL, ?, ?, ?, ?)
        `;
        const [result] = await connection.execute(insertSql, [user_id, appointment_date, appointment_time, reason || null, notes || null]);

        // 5. ยืนยันการบันทึกข้อมูล
        await connection.commit();
        res.status(201).json({ success: true, message: 'จองคิวสำเร็จ', appointmentId: result.insertId });

    } catch (error) {
        await connection.rollback();
        console.error('User Booking Error:', error);
        res.status(500).json({ success: false, message: 'ไม่สามารถจองคิวได้' });
    } finally {
        // 6. คืน Connection กลับเข้า Pool เสมอ
        if (connection) connection.release();
    }
};

exports.bookAppointmentByAdmin = async (req, res) => {
    const connection = await pool.getConnection();

    try {
        const { user_id, doctor_id, appointment_date, appointment_time, reason, notes } = req.body;

        if (!user_id || !doctor_id || !appointment_date || !appointment_time) {
            connection.release();
            return res.status(400).json({ success: false, message: 'กรุณากรอกข้อมูลผู้ป่วย แพทย์ วันที่ และเวลาให้ครบ' });
        }

        await connection.beginTransaction();

        const checkCapacitySql = `
            SELECT COUNT(id) as total_bookings 
            FROM appointments 
            WHERE appointment_date = ? AND appointment_time = ? AND status != 'cancelled'
            FOR UPDATE
        `;
        const [capacityResult] = await connection.execute(checkCapacitySql, [appointment_date, appointment_time]);
        
        // แก้ไขข้อความแจ้งเตือนให้ตรงกับเงื่อนไข (4 คน)
        if (capacityResult[0].total_bookings >= 4) {
            await connection.rollback();
            connection.release();
            return res.status(400).json({ success: false, message: 'คิวเวลานี้เต็มแล้ว (ครบ 4 คน)' });
        }

        const insertSql = `
            INSERT INTO appointments 
            (user_id, doctor_id, appointment_date, appointment_time, reason, notes) 
            VALUES (?, ?, ?, ?, ?, ?)
        `;
        const [result] = await connection.execute(insertSql, [user_id, doctor_id, appointment_date, appointment_time, reason || null, notes || null]);

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

        // ฟังก์ชันนี้แค่อ่านข้อมูลเพื่อแสดงผล จึงใช้ pool.execute ตามปกติได้เลย (ไม่ต้องใช้ Transaction)
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