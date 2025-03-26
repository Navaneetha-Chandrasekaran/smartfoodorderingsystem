CREATE DATABASE food_ordering;

USE food_ordering;


ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';
flush privileges;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sin_num VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('student', 'admin') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


alter table users add confirm_password varchar(255) not null;
ALTER TABLE users DROP COLUMN confirm_password;

CREATE TABLE food_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    availability BOOLEAN DEFAULT TRUE
);
drop table orders;
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    otp VARCHAR(6) NOT NULL,
    status ENUM('Pending', 'Verified', 'Completed') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    food_id INT NOT NULL,
    quantity INT NOT NULL,
    status ENUM('Pending', 'Preparing', 'Ready', 'Completed') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES users(id),
    FOREIGN KEY (food_id) REFERENCES food_items(id)
);


select * from users;
select * from food_items;
insert into food_items(name,price,availability) values ("burger",50.00,true);