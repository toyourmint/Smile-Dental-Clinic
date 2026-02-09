ALTER TABLE user_profiles
ADD COLUMN treatment_right 
  ENUM('gold_card','social_security','government','self_pay')
  NULL,

ADD COLUMN annual_budget DECIMAL(10,2) NULL,
ADD COLUMN used_budget DECIMAL(10,2) DEFAULT 0;
