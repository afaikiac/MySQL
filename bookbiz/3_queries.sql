-- Составить список авторов с указанием количества изданных книг
-- (в том числе в соавторстве).
SELECT COUNT(books_authors.au_id) AS book_count, CONCAT(au_lname,' ', au_fname) AS author
FROM books_authors,
     authors
WHERE authors.au_id = books_authors.au_id
GROUP BY books_authors.au_id
ORDER BY book_count;

-- Определить для каждого автора книгу с самым большим тиражом.
SELECT MAX(circulation) AS max_circulation, CONCAT(au_lname,' ', au_fname) AS author
FROM editions,
     authors,
     books_authors
WHERE editions.book_id = books_authors.book_id
  AND authors.au_id = books_authors.au_id
GROUP BY books_authors.au_id
ORDER BY max_circulation;

-- Определить авторов, для которых среднее число страниц в книге не превышает 100.
SELECT CONCAT(au_lname,' ', au_fname) AS author, AVG(num_pages) AS pages
FROM authors,
     editions,
     books_authors
WHERE authors.au_id = books_authors.au_id
  AND editions.book_id = books_authors.book_id
GROUP BY books_authors.au_id
HAVING pages <= 100;
