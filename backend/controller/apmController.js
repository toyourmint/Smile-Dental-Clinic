const pool = require('../config/db');

exports.bookAppointmentByUser = async (req, res) => {
    try {
        // 1. ดึง user_id จาก Token ที่ล็อกอินเข้ามา (ห้ามรับจาก req.body เด็ดขาด)
        const user_id = req.user.id; 
        const { appointment_date, appointment_time, reason, notes } = req.body;

        if (!appointment_date || !appointment_time) {
            return res.status(400).json({ success: false, message: 'กรุณาระบุวันที่และเวลา' });
        }

        // 2. เช็คโควตา 5 คนต่อช่วงเวลา
        const checkCapacitySql = `SELECT COUNT(id) as total_bookings 
        FROM appointments 
        WHERE appointment_date = ? AND appointment_time = ? AND status != 'cancelled'`;
        const [capacityResult] = await pool.execute(checkCapacitySql, [appointment_date, appointment_time]);
        
        if (capacityResult[0].total_bookings >= 5) {
            return res.status(400).json({ success: false, message: 'คิวเวลานี้เต็มแล้ว กรุณาเลือกเวลาอื่น' });
        }

        // 3. บันทึกข้อมูล (doctor_id เป็น null อัตโนมัติ)
        const insertSql = `
        INSERT INTO appointments 
        (user_id, doctor_id, appointment_date, appointment_time, reason, notes) 
        VALUES (?, NULL, ?, ?, ?, ?)
        `;
        const [result] = await pool.execute(insertSql, [user_id, appointment_date, appointment_time, reason || null, notes || null]);

        res.status(201).json({ success: true, message: 'จองคิวสำเร็จ', appointmentId: result.insertId });

    } catch (error) {
        console.error('User Booking Error:', error);
        res.status(500).json({ success: false, message: 'ไม่สามารถจองคิวได้' });
    }
};

exports.bookAppointmentByAdmin = async (req, res) => {
    try {
        // 1. แอดมินเป็นคนระบุ user_id และ doctor_id เอง
        const { user_id, doctor_id, appointment_date, appointment_time, reason, notes } = req.body;

        if (!user_id || !doctor_id || !appointment_date || !appointment_time) {
            return res.status(400).json({ success: false, message: 'กรุณากรอกข้อมูลผู้ป่วย แพทย์ วันที่ และเวลาให้ครบ' });
        }

        // 2. เช็คโควตา 5 คน
        const checkCapacitySql = `SELECT COUNT(id) as total_bookings FROM appointments WHERE appointment_date = ? AND appointment_time = ? AND status != 'cancelled'`;
        const [capacityResult] = await pool.execute(checkCapacitySql, [appointment_date, appointment_time]);
        
        if (capacityResult[0].total_bookings >= 5) {
            return res.status(400).json({ success: false, message: 'คิวเวลานี้เต็มแล้ว (ครบ 5 คน)' });
        }

        // 3. บันทึกข้อมูลแบบมีหมอ
        const insertSql = `INSERT INTO appointments (user_id, doctor_id, appointment_date, appointment_time, reason, notes) VALUES (?, ?, ?, ?, ?, ?)`;
        const [result] = await pool.execute(insertSql, [user_id, doctor_id, appointment_date, appointment_time, reason || null, notes || null]);

        res.status(201).json({ success: true, message: 'เพิ่มการนัดหมายสำเร็จ', appointmentId: result.insertId });

    } catch (error) {
        console.error('Admin Booking Error:', error);
        res.status(500).json({ success: false, message: 'ไม่สามารถเพิ่มการนัดหมายได้' });
    }
};

exports.getAvailableSlots = async (req, res) => {
    try {
        // 1. รับค่าวันที่มาจาก Frontend (ผ่าน query parameter เช่น /api/slots?date=2026-02-22)
        const { date } = req.query;

        if (!date) {
            return res.status(400).json({ success: false, message: 'กรุณาระบุวันที่' });
        }

        // 2. Query เพื่อนับจำนวนคิวที่ถูกจองไปแล้วในแต่ละช่วงเวลาของวันนั้น
        const sql = `
            SELECT appointment_time, COUNT(id) as booked_count 
            FROM appointments 
            WHERE appointment_date = ? 
              AND status != 'cancelled'
            GROUP BY appointment_time
        `;
        const [bookedSlots] = await pool.execute(sql, [date]);

        // 3. กำหนดช่วงเวลาทั้งหมดที่คลินิกเปิดให้บริการ (อ้างอิงจากภาพ UI ของคุณ)
        const allTimeSlots = [
            '09:00:00', '10:00:00', '11:00:00', '13:00:00', 
            '14:00:00', '15:00:00', '16:00:00', '17:00:00'
        ];

        // 4. นำข้อมูลจาก Database มาเทียบกับเวลาทั้งหมด เพื่อหาสถานะของแต่ละช่วงเวลา
        const slotsStatus = allTimeSlots.map(time => {
            // หาว่าเวลานี้มีคนจองไปกี่คน (ถ้าไม่มีใน Database คือ 0 คน)
            const foundSlot = bookedSlots.find(slot => slot.appointment_time === time);
            const currentBookings = foundSlot ? foundSlot.booked_count : 0;
            
            return {
                time: time,
                bookedCount: currentBookings,
                isFull: currentBookings >= 5 // ถ้าจองครบ 5 คน isFull จะเป็น true
            };
        });

        // 5. ส่งผลลัพธ์กลับไปให้แอปมือถือ
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