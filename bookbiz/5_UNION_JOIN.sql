-- Определить издательства не издавшие ни одной книги.
SELECT pub_name publisher
FROM publishers p
    LEFT JOIN (
      SELECT pub_id
      FROM editions
      ) AS e
    ON p.pub_id = e.pub_id
WHERE e.pub_id IS NULL
ORDER BY 1;

-- Вывести авторов с количеством опубликованных книг, если книг нет написать "отсутствуют"
-- 1
EXPLAIN SELECT CONCAT(au_lname, ' ', au_fname) author,
               IF(MIN(b_a.book_id) IS NULL , 'отсутствуют',
                 COUNT(b_a.book_id)) count_books
FROM authors a
    LEFT JOIN books_authors b_a
    ON a.au_id = b_a.au_id
GROUP BY a.au_id
ORDER BY 1;
-- 2
EXPLAIN SELECT CONCAT(au_lname, ' ', au_fname) author, IFNULL(b_a.count_b, 'отсутствуют') count_books
FROM authors a
    LEFT JOIN (
        SELECT au_id, COUNT(book_id) count_b
        FROM books_authors
        GROUP BY au_id
        ) AS b_a
ON a.au_id = b_a.au_id
ORDER BY 1;
-- 3
EXPLAIN SELECT CONCAT(au_lname, ' ', au_fname) author, CONVERT(COUNT(b_a.book_id), char) count_books
FROM authors a
    INNER JOIN books_authors b_a
    ON a.au_id = b_a.au_id
GROUP BY a.au_id

UNION

SELECT CONCAT(au_lname, ' ', au_fname) author, 'отсутствуют'
FROM authors a
    LEFT JOIN books_authors b_a
    ON a.au_id = b_a.au_id
WHERE b_a.book_id IS NULL
GROUP BY a.au_id
ORDER BY 1;

-- Вывести список книг с количеством изданий тираж которых 1000.
-- У 2 изданий из 4 тираж книги равнялся 1000 -> выход: 2.
-- 1
SELECT title, count_ed
FROM books b
    LEFT JOIN (
      SELECT book_id, COUNT(ed) count_ed
      FROM editions
      WHERE circulation = 1000
      GROUP BY book_id
      ) AS e
    ON b.book_id = e.book_id
ORDER BY 2 DESC;
-- 2
EXPLAIN SELECT title, COUNT(ed) count_ed
FROM books b
    LEFT JOIN editions e
    ON b.book_id = e.book_id
WHERE circulation = 1000
GROUP BY e.book_id

UNION

SELECT title, 0
FROM books
WHERE book_id IN (
    SELECT book_id
    FROM editions
    WHERE circulation != 1000
    GROUP BY book_id
    )
ORDER BY 2 DESC;

