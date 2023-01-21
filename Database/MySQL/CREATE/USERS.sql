ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'password';

ALTER USER 'user'@'%' IDENTIFIED WITH mysql_native_password BY 'password';

GRANT ALL PRIVILEGES ON *.* TO 'user'@'%';

FLUSH PRIVILEGES;
