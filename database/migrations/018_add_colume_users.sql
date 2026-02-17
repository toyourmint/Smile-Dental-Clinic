ALTER TABLE user_profiles
ADD CONSTRAINT fk_user_profiles
FOREIGN KEY (user_id)
REFERENCES users(id)
ON DELETE CASCADE;
