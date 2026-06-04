#!/bin/bash
export MSYS_NO_PATHCONV=1

# 결과를 저장할 폴더 생성
mkdir -p library_results

reset_data() {
    echo "Resetting library data..."
    docker compose exec -T postgres psql -h localhost -p 5432 -U dweb -d postgres -c "
        TRUNCATE rentals RESTART IDENTITY;
        UPDATE books SET stock = 100 WHERE book_id = 1;
        UPDATE books SET stock = 100 WHERE book_id = 2;
        UPDATE books SET stock = 100 WHERE book_id = 3;
    "
}

echo "=== [1] READ COMMITTED 격리 수준 테스트 ==="
reset_data
docker compose exec -T postgres pgbench -h localhost -p 5432 -U dweb -d postgres -f /library_workload.sql -n -c 10 -j 2 -T 20 > library_results/read_committed_10users.txt 2>library_results/read_committed_10users_err.txt

reset_data
docker compose exec -T postgres pgbench -h localhost -p 5432 -U dweb -d postgres -f /library_workload.sql -n -c 50 -j 4 -T 20 > library_results/read_committed_50users.txt 2>library_results/read_committed_50users_err.txt


echo "=== [2] SERIALIZABLE 격리 수준 테스트 ==="
reset_data
docker compose exec -T postgres pgbench -h localhost -p 5432 -U dweb -d postgres -f /library_workload_serializable.sql -n -c 10 -j 2 -T 20 > library_results/serializable_10users.txt 2>library_results/serializable_10users_err.txt

reset_data
docker compose exec -T postgres pgbench -h localhost -p 5432 -U dweb -d postgres -f /library_workload_serializable.sql -n -c 50 -j 4 -T 20 > library_results/serializable_50users.txt 2>library_results/serializable_50users_err.txt

echo "=== 벤치마킹 완료! library_results 폴더를 확인하세요. ==="