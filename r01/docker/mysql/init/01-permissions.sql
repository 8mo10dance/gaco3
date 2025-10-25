-- Create rails_app_user if not exists and grant all privileges
CREATE USER IF NOT EXISTS 'rails_app_user'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'rails_app_user'@'%';
FLUSH PRIVILEGES;