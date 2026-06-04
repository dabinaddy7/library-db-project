const express = require('express');
const { Pool } = require('pg');

const app = express();
app.use(express.json());
app.use(express.static('public'));

const pool = new Pool({
  user: 'dweb',
  host: 'localhost',
  database: 'postgres',
  password: '1234',
  port: 5432,
});

// [조회] 회원별 대여 현황
app.get('/api/users-rentals', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT u.user_id, u.name, u.email, COUNT(r.rental_id) AS rental_count
      FROM users u
      LEFT JOIN rentals r ON u.user_id = r.user_id
      GROUP BY u.user_id
      ORDER BY u.user_id ASC;
    `);
    res.json(result.rows);
  } catch (err) {
    res.status(500).send("서버 에러 발생");
  }
});

// [기능] 신규 회원 추가
app.post('/api/users', async (req, res) => {
  const { name, email } = req.body;
  try {
    await pool.query('INSERT INTO users (name, email) VALUES ($1, $2)', [name, email]);
    res.send("회원이 성공적으로 등록되었습니다!");
  } catch (err) {
    res.status(400).send("등록 실패 (이미 존재하는 이메일입니다)");
  }
});

// [조회] 특정 회원의 대여 목록
app.get('/api/users/:id/rentals', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT r.rental_id, b.book_id, b.title 
      FROM rentals r
      JOIN books b ON r.book_id = b.book_id
      WHERE r.user_id = $1;
    `, [req.params.id]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).send("목록 조회 실패");
  }
});

// [대여] 트랜잭션 + 중복 방지
app.post('/api/rent', async (req, res) => {
  const { user_id, book_id } = req.body;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    const dupCheck = await client.query('SELECT rental_id FROM rentals WHERE user_id = $1 AND book_id = $2', [user_id, book_id]);
    if (dupCheck.rows.length > 0) throw new Error("대여 불가: 이미 이 도서를 대여 중입니다!");

    const bookCheck = await client.query('SELECT stock FROM books WHERE book_id = $1', [book_id]);
    if (bookCheck.rows.length === 0 || bookCheck.rows[0].stock <= 0) throw new Error("대여 불가: 재고가 없습니다!");

    await client.query('INSERT INTO rentals (user_id, book_id) VALUES ($1, $2)', [user_id, book_id]);
    await client.query('UPDATE books SET stock = stock - 1 WHERE book_id = $1', [book_id]);

    await client.query('COMMIT');
    res.send("대여가 성공적으로 완료되었습니다!");
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(400).send(err.message);
  } finally {
    client.release();
  }
});

// 🚀 [복구된 반납 기능] 트랜잭션 (DELETE & UPDATE)
app.post('/api/return', async (req, res) => {
  const { rental_id, book_id } = req.body;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('DELETE FROM rentals WHERE rental_id = $1', [rental_id]);
    await client.query('UPDATE books SET stock = stock + 1 WHERE book_id = $1', [book_id]);
    await client.query('COMMIT');
    res.send("도서가 성공적으로 반납되었습니다!");
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(400).send("반납 실패");
  } finally {
    client.release();
  }
});

// 🚀 [현실적 업그레이드] 먹튀 방지 회원 탈퇴 로직
app.delete('/api/users/:id', async (req, res) => {
  try {
    // 1. 빌려간 책이 있는지 먼저 검사!
    const rentalCheck = await pool.query('SELECT COUNT(*) FROM rentals WHERE user_id = $1', [req.params.id]);
    if (parseInt(rentalCheck.rows[0].count) > 0) {
      return res.status(400).send("탈퇴 불가: 아직 반납하지 않은 도서가 있습니다!");
    }
    
    // 2. 미반납 도서가 없으면 정상 탈퇴
    await pool.query('DELETE FROM users WHERE user_id = $1', [req.params.id]);
    res.send("회원 탈퇴가 완료되었습니다.");
  } catch (err) {
    res.status(500).send("탈퇴 처리 중 오류 발생");
  }
});

// 전체 도서 목록
app.get('/api/books', async (req, res) => {
  const result = await pool.query('SELECT * FROM books ORDER BY book_id ASC');
  res.json(result.rows);
});

// 서버 가동 및 브라우저 오픈
app.listen(3000, () => {
  console.log('✅ [SUCCESS] 백엔드 웹 서버가 가동 중입니다!');
  const { exec } = require('child_process');
  exec('start http://localhost:3000');
});