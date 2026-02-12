ALTER TABLE user_profiles
ADD COLUMN allergies TEXT AFTER gender,
ADD COLUMN disease TEXT AFTER allergies,
ADD COLUMN medicine TEXT AFTER disease;
