CREATE TABLE queues (
    id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT,
    user_id INT NOT NULL,
    queue_number INT NOT NULL,
    queue_date DATE NOT NULL,
    room ENUM('A','B') NULL,   -- 👈 mockup ห้อง A/B
    status ENUM('waiting','in_room','done') DEFAULT 'waiting',

    FOREIGN KEY (appointment_id) REFERENCES appointments(id),
    FOREIGN KEY (user_id) REFERENCES user_profiles(user_id),
    UNIQUE (queue_date, queue_number)
);
