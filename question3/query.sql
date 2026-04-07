-- 題目三:找出分數第二名的學生在哪個班
-- Database: student
-- Table: score (name, score),class (name, class)

-- 解法一：DENSE_RANK
-- 用 DENSE_RANK，這樣就算有人並列第一，第二名還是第二名不會變第三
SELECT c.class
FROM (
  SELECT name, DENSE_RANK() OVER (ORDER BY score DESC) AS rnk
  FROM score
) s
JOIN class c ON s.name = c.name
WHERE s.rnk = 2;

-- 解法二：LIMIT OFFSET
-- 先對 score 去重排序，OFFSET 1 跳過第一名，LIMIT 1 取第二名分數
-- 再找出擁有該分數的學生所在班級
SELECT c.class
FROM score s
JOIN class c ON s.name = c.name
WHERE s.score = (
  SELECT DISTINCT score
  FROM score
  ORDER BY score DESC
  LIMIT 1 OFFSET 1
);

-- 驗算：Mary 100 第一、John 97 第二 → John 在 A 班，結果應為 A
