-- Издание
-- 1
SELECT isbn, num_pages
FROM editions
WHERE num_pages < 100;
-- 2
SELECT isbn, num_pages
FROM editions
WHERE num_pages BETWEEN 100 AND 200;
-- 3
SELECT isbn, ed
FROM editions
WHERE ed IN (1, 2);
-- 4
SELECT *
FROM editions
WHERE isbn LIKE '372%';
-- 5
SELECT isbn
FROM editions
WHERE num_pages IS NULL;

-- Книга
-- 1
SELECT title
FROM books
WHERE book_id <> 1;
-- 2
SELECT *
FROM books
WHERE book_id BETWEEN 5 AND 7;
-- 3
SELECT *
FROM books
WHERE book_id IN (3, 4, 5, 10);
-- 4
SELECT *
FROM books
WHERE title LIKE '%ti%';
-- 5
SELECT DISTINCT title
FROM books;

-- Автор
-- 1
SELECT *
FROM authors
WHERE au_id >= 5;
-- 2
SELECT *
FROM authors
WHERE au_id BETWEEN 3 AND 7;
-- 3
SELECT *
FROM authors
WHERE au_lname IN ('Ringer', 'Greene');
-- 4
SELECT *
FROM authors
WHERE au_fname LIKE 'An%';
-- 5
SELECT DISTINCT au_lname
FROM authors
ORDER BY au_lname ASC;

-- Издатель
-- 1
SELECT pub_name, city
FROM publishers
WHERE city = 'Boston';
-- 2
SELECT pub_name
FROM publishers
WHERE pub_id BETWEEN 2 AND 4;
-- 3
SELECT *
FROM publishers
WHERE city IN ('Boston', 'Washington');
-- 4
SELECT *
FROM publishers
WHERE pub_name LIKE '_e%';
-- 5
SELECT *
FROM publishers
WHERE state IS NULL;
