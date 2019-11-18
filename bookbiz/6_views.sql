-- Создать модифицируемое представление.
CREATE OR REPLACE
    ALGORITHM = MERGE
VIEW `stored_editions` (`isbn`, `book_id`, `pub_id`, `circulation`)
AS
SELECT `isbn`, `book_id`, `pub_id`, `circulation`
FROM `editions`
WHERE `date_stamp` > '2012-12-12';

-- Выполнить для полученного представления запрос INSERT.
INSERT INTO `stored_editions`
VALUES (3721321469000, 18, 1, 3000000000);

-- =====================================================================================================================

-- Создать представление по книгам с указанием
-- одного из авторов и последнего года издания.
CREATE OR REPLACE
    ALGORITHM = TEMPTABLE
VIEW `last_book_edition` (`book_id`, `title`, `author`, `date_stamp`)
AS
SELECT `b`.`book_id`, `b`.`title`, `t2`.`author`, `t1`.`date_stamp`
-- У книги точно есть id и название.
FROM `books` `b`
    -- Даты издания может и не быть.
    LEFT JOIN (
        -- Находим дату выпуска последнего издания.
        SELECT `book_id`, `date_stamp`
        FROM `editions`
        GROUP BY `book_id`
        HAVING MAX(`date_stamp`)
        ) AS t1
    -- Связываем по book_id.
    ON `b`.`book_id` = `t1`.`book_id`
    -- Автора может и не быть.
    LEFT JOIN (
        -- Находим какого-нибудь самого первого автора книги MIN().
        SELECT `b_a`.`book_id`,
               MIN(CONCAT(`a`.`au_lname`, ' ', `a`.`au_fname`)) author
        FROM books_authors `b_a`,
             authors `a`
        -- Так как мы берём 1 автора из множества `b_a`.`book_id`,
        -- то сзязь 1-1 => смысла использовать JOIN нет.
        WHERE `a`.`au_id` IN (`b_a`.`au_id`)
        GROUP BY `b_a`.`book_id`
        ) AS `t2`
    -- Связываем по book_id.
    ON `b`.`book_id` = `t2`.`book_id`
GROUP BY `b`.`book_id`;

-- Second variant
-- Не отображает книги с отсутствующими значениями полей.
CREATE OR REPLACE
    ALGORITHM = TEMPTABLE
VIEW `last_book_edition` (`book_id`, `title`, `author`, `date_stamp`)
AS
SELECT `b_a`.`book_id`,
       `b`.`title`,
       MIN(CONCAT(`a`.`au_lname`, ' ', `a`.`au_fname`)),
       `e`.`date_stamp`
FROM `books` `b`,
     `authors` `a`,
     `editions` `e`,
     `books_authors` `b_a`

WHERE `b`.`book_id` = `b_a`.`book_id`
  AND `a`.`au_id` IN (`b_a`.`au_id`)
  AND `e`.`book_id` = `b_a`.`book_id`
  AND `e`.`isbn` IN (
        SELECT `isbn`
        FROM `editions` `e`
        GROUP BY `e`.`book_id`
        HAVING MAX(`e`.`date_stamp`)
        )
GROUP BY `b_a`.`book_id`;

-- =====================================================================================================================

-- Создать итоговое представление по авторам с указанием
-- количества разных соавторов,
-- количества изданных книг,
-- количества переизданий его книг.
CREATE OR REPLACE
    ALGORITHM = TEMPTABLE
VIEW `author_description` (`au_id`, `author`, `collaborators`, `count_books`, `books_editions`)
AS
SELECT `t0`.`au_id`,
       CONCAT(`t0`.`au_lname`, ' ', `t0`.`au_fname`) `author`,
       `t1`.`count_collab`,
       `t2`.`count_books`,
       `t2`.`all_isbn`
-- У автора точно есть id и ФИО.
FROM `authors` `t0`
    -- Соавторов может и не быть.
    LEFT JOIN (
        -- Подсчёт количества соавторов для каждого автора,
        -- который появился в подзапросе.
        SELECT `a`.`au_id`,
               COUNT(`a_a`.`collab`) `count_collab`
        FROM `authors` `a`
            INNER JOIN (
                -- Все воозможные комбинации соавторов
                -- для книг у которых не менее 2 авторов.
                SELECT `a_b`.`au_id` `authors`, `b_a`.`au_id` `collab`
                FROM `books_authors` `a_b`,
                     `books_authors` `b_a`
                WHERE `a_b`.`book_id` = `b_a`.`book_id`
                  AND `a_b`.`au_id` != `b_a`.`au_id`
                ) AS `a_a`
            ON `a`.`au_id` = `a_a`.`authors`
        -- У 1 автора много соавторов.
        GROUP BY `a`.`au_id`
        ) AS `t1`
    ON `t0`.`au_id` = `t1`.`au_id`
    -- У автора может и не быть книг.
    LEFT JOIN (
        -- Подсчёт общего количества книг и их изданий для каждого автора,
        -- у которого они есть.
        SELECT `t_b`.`au_id`,
               COUNT(`p0`.`book_id`) `count_books`,
               SUM(`p0`.`c_e`)   `all_isbn`
        FROM books_authors `t_b`
            INNER JOIN (
                -- Подсчёт количества изданий для каждой книги.
                SELECT `book_id`, COUNT(`isbn`) `c_e`
                FROM `editions`
                GROUP BY `book_id`
            ) AS `p0`
            ON `t_b`.`book_id` = `p0`.`book_id`
        -- У 1 автора много книг.
        GROUP BY `t_b`.`au_id`
    ) AS `t2`
    ON `t0`.`au_id` = `t2`.`au_id`
GROUP BY `t0`.`au_id`;

-- Second variant
-- Не отображает авторов без книг.
SELECT CONCAT(t0.au_lname, ' ', t0.au_fname) autor, t2.c_collab, t2.CountBoks, t2.Allisbn
FROM authors t0
    INNER JOIN(
        SELECT t1.au,
               t00.c_collab,
               t1.CountBoks,
               t1.Allisbn
        FROM (SELECT t_b.au_id     au,
                     Count(p0.c_e) CountBoks,
                     Sum(p0.c_e)   Allisbn
              FROM books_authors t_b
                  INNER JOIN (
                      SELECT book_id, COUNT(isbn) c_e
                      FROM `editions`
                      GROUP BY `book_id`
                      ) AS p0
                  ON t_b.book_id = p0.book_id
              GROUP BY t_b.au_id
              ) AS t1,
             -- Подсчёт соавторов для каждого автора,
             -- у которого есть хотя бы 1 книга (возможно 0 соавторов)
             (SELECT a.au_id,
                     COUNT(a_a.collab) - 1 AS c_collab
              FROM authors a
                  INNER JOIN (
                      SELECT DISTINCT a_b.au_id authors,
                                      b_a.au_id collab
                      FROM books_authors a_b,
                           books_authors b_a
                      WHERE a_b.book_id = b_a.book_id
                      ) AS a_a
                  ON a.au_id = a_a.authors
              GROUP BY a.au_id
              ) AS t00
        WHERE t1.au = t00.au_id
        ) AS t2
    ON t0.au_id = t2.au
GROUP BY t0.au_id;

-- =====================================================================================================================
-- =====================================================================================================================
-- =====================================================================================================================
-- =====================================================================================================================
-- =====================================================================================================================

-- Collaborators short version
SELECT DISTINCT a_b.au_id, b_a.au_id
FROM books_authors a_b,
    (SELECT book_id, au_id
     FROM books_authors) as b_a
WHERE a_b.book_id = b_a.book_id
GROUP BY a_b.au_id;

-- Collaborators long version
SELECT a.au_id, COUNT(a_a.collab)
FROM authors a
         INNER JOIN (SELECT DISTINCT a_b.au_id authors, b_a.au_id collab
                    FROM books_authors a_b,
                         (SELECT book_id, au_id
                          FROM books_authors) as b_a
                    WHERE a_b.book_id = b_a.book_id) AS a_a
         ON a.au_id = a_a.authors
GROUP BY a.au_id;

-- Collaborators ERROR long version
SELECT DISTINCT a.au_id, a_a.collab
FROM books_authors a
         INNER JOIN (SELECT DISTINCT a_b.au_id authors, b_a.au_id collab
                    FROM books_authors a_b,
                         (SELECT book_id, au_id
                          FROM books_authors) as b_a
                    WHERE a_b.book_id = b_a.book_id) AS a_a
         ON a.au_id = a_a.authors;


# SELECT b0.au_id, Bit_count(Bit_or(1<<b_a2.collab));

-- GOOD ERROR TRY
SELECT MIN(CONCAT(t0.au_lname, ' ', t0.au_fname)) autor, COUNT(t1.collab) - 1, COUNT(t1.c_e) count_books, SUM(t1.c_e)   all_isbn
FROM authors t0

LEFT JOIN
    (SELECT DISTINCT t_b.au_id,
                     a_a.collab,
                     p0.c_e
     FROM books_authors t_b
         INNER JOIN
             (SELECT book_id, COUNT(isbn) c_e
              FROM `editions`
              GROUP BY `book_id`) p0
         ON t_b.book_id = p0.book_id

         INNER JOIN
            (SELECT DISTINCT a_b.au_id authors, b_a.au_id collab
                    FROM books_authors a_b,
                         (SELECT book_id, au_id
                          FROM books_authors) as b_a
                    WHERE a_b.book_id = b_a.book_id
            ) AS a_a
         ON t_b.au_id = a_a.authors) AS t1

ON t0.au_id = t1.au_id
GROUP BY t0.au_id;

-- ERROR long version
SELECT concat(t0.au_id, ': ', t0.au_fname) autor, t1.colab, t1.CountBoks, t1.Allisbn
from authors t0
         LEFT JOIN
     (SELECT t_b.au_id                         au,
             Sum(t_isb.c_a) - Count(t_b.au_id) colab,
             Count(t_isb.c_e)                  CountBoks,
             Sum(t_isb.c_e)                    Allisbn
      FROM books_authors t_b
               LEFT JOIN
           (SELECT p0.book_id, p0.c_e, p1.c_a
            FROM (SELECT book_id, COUNT(isbn) c_e
                  FROM `editions`
                  GROUP BY `book_id`) p0,
                 (SELECT book_id, COUNT(au_id) c_a
                  FROM books_authors
                  GROUP BY `book_id`) p1
            WHERE p0.`book_id` = p1.`book_id`
           ) t_isb
           ON t_b.book_id = t_isb.book_id
      GROUP BY t_b.au_id) t1
     ON t0.au_id = t1.au;

-- ERROR short version
SELECT t_b.au_id                         au,
       Sum(t_isb.c_a) - Count(t_b.au_id) colab,
       Count(t_isb.c_e)                  CountBoks,
       Sum(t_isb.c_e)                    Allisbn
FROM books_authors t_b
         Left Join
     (Select p0.book_id, p0.c_e, p1.c_a
      FROM (SELECT book_id, COUNT(isbn) c_e
            FROM `editions`
            GROUP BY `book_id`) p0,
           (SELECT book_id, Count(au_id) c_a
            FROM books_authors
            GROUP BY `book_id`) p1
      WHERE p0.`book_id` = p1.`book_id`
     ) t_isb
     ON t_b.book_id = t_isb.book_id
GROUP BY t_b.au_id;

-- ERROR VIEW
CREATE OR REPLACE
    ALGORITHM = TEMPTABLE
VIEW `author_description` (`author`, `count_books`, `collaborators`, `books_editions`)
AS
SELECT `s1`.`author`, `s2`.`count_b`, `s3_s4`.`ddd`, `s3_s4`.`count_ed`
FROM (SELECT `au_id`, CONCAT(`au_lname`, ' ', `au_fname`) `author`
      FROM `authors`
     ) AS `s1`
         LEFT JOIN (SELECT `au_id`, COUNT(`book_id`) `count_b`
                    FROM `books_authors`
                    GROUP BY `au_id`) AS `s2`
         ON `s1`.`au_id` = `s2`.`au_id`

         LEFT JOIN (SELECT `b_a`.`au_id`, SUM(`t0`.`count_b_ed`) `count_ed`, `t0`.`count_collab` -1 as ddd
                    FROM books_authors `b_a`
                        LEFT JOIN
                             (SELECT `e`.`book_id`, COUNT(`e`.`isbn`) `count_b_ed`, `s3`.`count_collab`
                              FROM `editions` `e`
                                       INNER JOIN(
                                            SELECT `book_id`, COUNT(`au_id`) `count_collab`
                                            FROM books_authors
                                            GROUP BY `book_id`) AS `s3`
                                       ON `e`.`book_id` = `s3`.`book_id`
                              GROUP BY `book_id`) AS `t0`
                        ON `b_a`.`book_id` = `t0`.`book_id`
                    GROUP BY `b_a`.`au_id`) AS `s3_s4`
         ON `s1`.`au_id` = `s3_s4`.`au_id`;

-- Like first correct version
CREATE OR REPLACE
    ALGORITHM = TEMPTABLE
VIEW `author_description` (`author`, `collaborators`, `count_books`, `books_editions`)
AS
SELECT MIN(CONCAT(t0.au_lname, ' ', t0.au_fname)) autor, t2.count_collab, t1.count_books, t1.all_isbn
FROM authors t0
    LEFT JOIN
        -- Подсчёт общего количества книг и их изданий для каждого автора
        (SELECT t_b.au_id,
                COUNT(p0.c_e) count_books,
                SUM(p0.c_e)   all_isbn
         FROM books_authors t_b
             INNER JOIN
                 (SELECT book_id, COUNT(isbn) c_e
                  FROM `editions`
                  GROUP BY `book_id`) p0
             ON t_b.book_id = p0.book_id
         GROUP BY t_b.au_id) AS t1
    ON t0.au_id = t1.au_id

    LEFT JOIN
        -- Подсчёт количества соавторов для каждого автора
        (SELECT a.au_id,
                COUNT(a_a.collab) - 1 AS count_collab
         FROM authors a
             INNER JOIN
                 (SELECT DISTINCT a_b.au_id authors, b_a.au_id collab
                  FROM books_authors a_b,
                       (SELECT book_id, au_id
                        FROM books_authors) as b_a
                  WHERE a_b.book_id = b_a.book_id) AS a_a
             ON a.au_id = a_a.authors
         GROUP BY a.au_id) AS t2
    ON t0.au_id = t2.au_id
GROUP BY t0.au_id;

-- Создать итоговое представление по авторам с указанием
-- количества разных соавторов,
-- количества изданных книг,
-- количества переизданий его книг.
CREATE OR REPLACE
    ALGORITHM = TEMPTABLE
VIEW `author_description` (`author`, `collaborators`, `count_books`, `books_editions`)
AS
SELECT MIN(CONCAT(t0.au_lname, ' ', t0.au_fname)) autor, t2.count_collab, t1.count_books, t1.all_isbn
FROM authors t0
    LEFT JOIN
        -- Подсчёт общего количества книг и их изданий для каждого автора.
        (SELECT t_b.au_id,
                COUNT(p0.c_e) count_books,
                SUM(p0.c_e)   all_isbn
         FROM books_authors t_b
             INNER JOIN
                 -- Подсчёт количества изданий для каждой книги.
                 (SELECT book_id, COUNT(isbn) c_e
                  FROM `editions`
                  GROUP BY `book_id`) p0
             ON t_b.book_id = p0.book_id
         GROUP BY t_b.au_id) AS t1
    ON t0.au_id = t1.au_id

    LEFT JOIN
        -- Подсчёт количества соавторов для каждого автора,
        -- который появился в подзапросе.
        (SELECT a.au_id,
                COUNT(a_a.collab) count_collab
         FROM authors a
             INNER JOIN
                 -- Все воозможные комбинации соавторов
                 -- для книг у которых не менее 2 авторов.
                 (SELECT a_b.au_id authors, b_a.au_id collab
                  FROM books_authors a_b,
                       books_authors b_a
                  WHERE a_b.book_id = b_a.book_id
                    AND a_b.au_id != b_a.au_id) AS a_a
             ON a.au_id = a_a.authors
         GROUP BY a.au_id) AS t2
    ON t0.au_id = t2.au_id
GROUP BY t0.au_id;