CREATE TABLE user_profiles (
  user_id INT PRIMARY KEY,

  citizen_id VARCHAR(13) UNIQUE,
  title VARCHAR(20),
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  birth_date DATE,
  gender ENUM('male','female','other'),

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id)
);
