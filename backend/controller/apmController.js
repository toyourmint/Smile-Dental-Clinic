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
            (user_id, doctor_id, appointment_date, appointment_time, reason, notes, status) 
            VALUES (?, NULL, ?, ?, ?, ?, 'booking')
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

        // 💡 2. หา id หมอให้ถูกต้อง (แก้ตามไฟล์ 009_create_doctors.sql)
        let doctor_id = null;
        if (doctor_name && doctor_name !== "-") {
            const [docs] = await connection.execute('SELECT id FROM doctors WHERE doctor_name = ? LIMIT 1', [doctor_name]);
            if (docs.length > 0) {
                doctor_id = docs[0].id;
            }
        }

        // 3. เช็คโควตาคิว 4 คน
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

        // 💡 4. บันทึกข้อมูลเข้าตาราง (ใส่ doctor_id และ notes แยกกันอย่างชัดเจน)
        const insertSql = `
            INSERT INTO appointments 
            (user_id, doctor_id, appointment_date, appointment_time, reason, notes, status) 
            VALUES (?, ?, ?, ?, ?, ?, 'booking')
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

// 💡 ดึงข้อมูลตาราง โดยเชื่อมกับ d.id ของหมอให้ถูกต้อง และเพิ่ม hn, title, phone, status
exports.getAllAppointments = async (req, res) => {
    try {
        const sql = `
            SELECT 
                a.id AS apt_id,
                a.appointment_date,
                a.appointment_time,
                a.reason,
                a.notes,
                a.status,          -- 💡 เพิ่ม status
                p.hn,              -- 💡 เพิ่ม hn
                p.title,           -- 💡 เพิ่ม title
                p.first_name,
                p.last_name,
                u.phone,           -- 💡 เพิ่ม phone
                d.doctor_name
            FROM appointments a
            JOIN users u ON a.user_id = u.id
            JOIN user_profiles p ON u.id = p.user_id
            LEFT JOIN doctors d ON a.doctor_id = d.id
            ORDER BY a.appointment_date ASC, a.appointment_time ASC
        `;

        const [rows] = await pool.execute(sql);

        res.status(200).json({
            success: true,
            appointments: rows
        });

    } catch (error) {
        console.error('Error fetching appointments:', error);
        res.status(500).json({ success: false });
    }
};


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
exports.rescheduleAppointment = async (req, res) => {
  try {
    const { id } = req.params;
    const { appointment_date, appointment_time } = req.body;

    if (!appointment_date || !appointment_time) {
      return res.status(400).json({
        success: false,
        message: 'กรุณาระบุวันและเวลาใหม่'
      });
    }

    // เช็คว่าช่วงเวลานั้นเต็มหรือยัง
    const checkSql = `
      SELECT COUNT(id) as total
      FROM appointments
      WHERE appointment_date = ?
        AND appointment_time = ?
        AND status != 'cancelled'
        AND id != ?
    `;

    const [rows] = await pool.execute(checkSql, [
      appointment_date,
      appointment_time,
      id
    ]);

    if (rows[0].total >= 4) {
      return res.status(400).json({
        success: false,
        message: 'ช่วงเวลานี้เต็มแล้ว'
      });
    }

    await pool.execute(
      `UPDATE appointments
       SET appointment_date = ?, appointment_time = ?
       WHERE id = ?`,
      [appointment_date, appointment_time, id]
    );

    res.json({ success: true, message: 'เลื่อนนัดสำเร็จ' });

  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false });
  }
};

exports.editAppointment = async (req, res) => {
    const connection = await pool.getConnection();

    try {
        const { id } = req.params; 
        const { doctor_name, appointment_date, appointment_time, reason, notes } = req.body;

        if (!appointment_date || !appointment_time) {
            connection.release();
            return res.status(400).json({ success: false, message: 'กรุณาระบุวันที่และเวลา' });
        }

        await connection.beginTransaction();

        // 1. หา id หมอจากชื่อ (ถ้ามีการเปลี่ยนหมอ)
        let doctor_id = null;
        if (doctor_name && doctor_name !== "-") {
            const [docs] = await connection.execute('SELECT id FROM doctors WHERE doctor_name = ? LIMIT 1', [doctor_name]);
            if (docs.length > 0) {
                doctor_id = docs[0].id;
            }
        }

        // 2. เช็คโควตาคิว 4 คน (ต้องข้ามการนับคิวตัวเองด้วยเงื่อนไข AND id != ?)
        const checkCapacitySql = `
            SELECT COUNT(id) as total_bookings 
            FROM appointments 
            WHERE appointment_date = ? AND appointment_time = ? AND status != 'cancelled' AND id != ?
            FOR UPDATE
        `;
        const [capacityResult] = await connection.execute(checkCapacitySql, [appointment_date, appointment_time, id]);
        
        if (capacityResult[0].total_bookings >= 4) {
            await connection.rollback();
            connection.release();
            return res.status(400).json({ success: false, message: 'คิวเวลานี้เต็มแล้ว (ครบ 4 คน)' });
        }

        // 3. บันทึกการแก้ไขลงตาราง (ไม่อัปเดต user_id)
        const updateSql = `
            UPDATE appointments 
            SET doctor_id = ?, appointment_date = ?, appointment_time = ?, reason = ?, notes = ?
            WHERE id = ?
        `;
        await connection.execute(updateSql, [doctor_id, appointment_date, appointment_time, reason || null, notes || null, id]);

        await connection.commit();
        res.status(200).json({ success: true, message: 'แก้ไขการนัดหมายสำเร็จ' });

    } catch (error) {
        await connection.rollback();
        console.error('Edit Appointment Error:', error);
        res.status(500).json({ success: false, message: 'ไม่สามารถแก้ไขข้อมูลได้' });
    } finally {
        if (connection) connection.release();
    }
};
exports.getMyAppointments = async (req, res) => {
  try {
    const userId = req.user.id;

    const sql = `
      SELECT 
        a.id,
        a.reason,
        a.appointment_date,
        a.appointment_time,
        p.first_name,
        p.last_name,
        d.doctor_name
      FROM appointments a
      JOIN user_profiles p ON p.user_id = a.user_id
      LEFT JOIN doctors d ON d.id = a.doctor_id
      WHERE a.user_id = ?
        AND a.status != 'cancelled'
      ORDER BY a.id DESC
    `;

    const [rows] = await pool.execute(sql, [userId]);

    res.json({ appointments: rows });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'error' });
  }
};


