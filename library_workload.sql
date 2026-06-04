-- 1. 트랜잭션 시작
BEGIN;

-- 2. 임의의 회원 ID(1~2)와 도서 ID(1~3)를 무작위로 선택해 중복 대여 확인
SELECT rental_id FROM rentals WHERE user_id = (random() * 1 + 1)::int AND book_id = (random() * 2 + 1)::int;

-- 3. 임의의 도서 재고 감소 (UPDATE)
UPDATE books SET stock = stock - 1 WHERE book_id = (random() * 2 + 1)::int AND stock > 0;

-- 4. 대여 이력 추가 (INSERT)
INSERT INTO rentals (user_id, book_id) VALUES ((random() * 1 + 1)::int, (random() * 2 + 1)::int);

-- 5. 최종 반영
COMMIT;