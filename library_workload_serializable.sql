-- 1. 격리 수준을 가장 높은 SERIALIZABLE로 설정하여 트랜잭션 시작
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- 2. 중복 검사
SELECT rental_id FROM rentals WHERE user_id = (random() * 1 + 1)::int AND book_id = (random() * 2 + 1)::int;

-- 3. 도서 재고 감소
UPDATE books SET stock = stock - 1 WHERE book_id = (random() * 2 + 1)::int AND stock > 0;

-- 4. 대여 이력 추가
INSERT INTO rentals (user_id, book_id) VALUES ((random() * 1 + 1)::int, (random() * 2 + 1)::int);

COMMIT;