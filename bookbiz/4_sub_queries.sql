-- Определить авторов у которых имеются книги с максимальным тиражом больше среднего.
SELECT MAX(circulation) max_circulation, CONCAT(au_lname,' ', au_fname) author
FROM editions e,
     authors a,
     books_authors b_a
WHERE e.book_id = b_a.book_id
  AND a.au_id = b_a.au_id
  AND e.circulation > (
    SELECT AVG(circulation)
    FROM editions
    )
GROUP BY b_a.au_id
ORDER BY 1;

-- Определить авторов, чьи книги опубликованы более чем в 2 разных изданиях.
SELECT CONCAT(au_lname,' ', au_fname) author, MIN(title) title
FROM authors a,
     books b,
     books_authors b_a
WHERE a.au_id = b_a.au_id
  AND b.book_id = b_a.book_id
  AND b_a.book_id IN (
    SELECT book_id
    FROM editions
    GROUP BY book_id
    HAVING COUNT(DISTINCT pub_id) > 2 -- много изданий одного издательства
    )
GROUP BY b_a.au_id
ORDER BY 1;

-- Увеличить тираж книги, если она имеет 2-х и более авторов.
UPDATE editions
SET circulation = circulation + 100
WHERE editions.book_id IN (
    SELECT book_id
    FROM books_authors
    GROUP BY book_id
    HAVING COUNT(au_id) >= 2
    );