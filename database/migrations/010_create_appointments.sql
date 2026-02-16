CREATE TABLE appointments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    reason VARCHAR(255),  -- 👈 รายละเอียดการนัด
    notes TEXT,           -- 👈 หมายเหตุเพิ่มเติม
    status ENUM('booking','arrived','completed','cancelled') 
        DEFAULT 'booking',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES user_profiles(user_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(id)
);
