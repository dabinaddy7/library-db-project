-- 기존 테이블이 있다면 무결성을 위해 순서대로 삭제
DROP TABLE IF EXISTS rentals;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS users;

-- 1. 회원 테이블 (부모)
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

-- 2. 도서 테이블 (부모)
CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    author VARCHAR(100) NOT NULL,
    stock INT NOT NULL CHECK (stock >= 0) -- 재고는 절대 0 미만이 될 수 없음!
);

-- 3. 도서 대여 이력 테이블 (자식 - users와 books를 연결)
CREATE TABLE rentals (
    rental_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE, -- 회원이 탈퇴하면 대여 기록도 함께 연쇄 삭제! (CASCADE)
    book_id INT NOT NULL REFERENCES books(book_id) ON DELETE CASCADE, -- 책이 폐기되면 대여 기록도 함께 연쇄 삭제!
    rented_at TIMESTAMP DEFAULT NOW()
);

-- 초기 테스트용 데이터 적재 (INSERT)
INSERT INTO users (name, email) VALUES 
('임다빈', 'dabin@inu.ac.kr'),
('홍길동', 'gildong@test.com');

INSERT INTO books (title, author, stock) VALUES 
('맛있는 데이터베이스', '김교수', 3),
('Node.js 웹 프로그래밍', '박강사', 1),
('오픈소스 오픈공학', '최연구', 5);