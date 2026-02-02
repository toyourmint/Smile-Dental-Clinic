CREATE TABLE user_addresses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,

  address_line TEXT,
  subdistrict VARCHAR(100),
  district VARCHAR(100),
  province VARCHAR(100),
  postal_code VARCHAR(10),

  FOREIGN KEY (user_id) REFERENCES users(id)
);
