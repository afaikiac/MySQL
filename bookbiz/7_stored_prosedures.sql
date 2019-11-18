-- Создать процедуру, вставляющую записи через первое представление
-- из предыдущего задания.
DROP PROCEDURE IF EXISTS `insert_edition`;
DELIMITER //
CREATE PROCEDURE `insert_edition`(IN isbn CHAR(13),
                                  IN book_id INT,
                                  IN pub_id INT,
                                  IN circulation BIGINT)
    LANGUAGE SQL
    NOT DETERMINISTIC
    MODIFIES SQL DATA
    SQL SECURITY DEFINER
BEGIN
    INSERT INTO `stored_editions`
    VALUES (isbn, book_id, pub_id, circulation);
END//
DELIMITER ;

-- Вставить как минимум 2 записи.
CALL `insert_edition`(3721321469001, 18, 1, 5000000000);
CALL `insert_edition`(3721321469022, 18, 1, 50000000);

-- =====================================================================================================================

-- Получить результат формируемый третьем представлением
-- (предыдущего задания) через выполнение нескольких запросов.
DROP PROCEDURE IF EXISTS `author_description`;
DELIMITER //
CREATE PROCEDURE `author_description`()
    LANGUAGE SQL
    NOT DETERMINISTIC
    READS SQL DATA
    SQL SECURITY DEFINER
BEGIN

SELECT `t0`.`au_id`,
       CONCAT(`t0`.`au_lname`, ' ', `t0`.`au_fname`) `author`,
       `t1`.`count_collab`,
       `t2`.`count_books`,
       `t2`.`all_isbn`
FROM `authors` `t0`
    LEFT JOIN (
        SELECT `a`.`au_id`,
               COUNT(`a_a`.`collab`) `count_collab`
        FROM `authors` `a`
            INNER JOIN (
                SELECT `a_b`.`au_id` `authors`, `b_a`.`au_id` `collab`
                FROM `books_authors` `a_b`,
                     `books_authors` `b_a`
                WHERE `a_b`.`book_id` = `b_a`.`book_id`
                  AND `a_b`.`au_id` != `b_a`.`au_id`
                ) AS `a_a`
            ON `a`.`au_id` = `a_a`.`authors`
        GROUP BY `a`.`au_id`
        ) AS `t1`
    ON `t0`.`au_id` = `t1`.`au_id`
    LEFT JOIN (
        SELECT `t_b`.`au_id`,
               COUNT(`p0`.`book_id`) `count_books`,
               SUM(`p0`.`c_e`)   `all_isbn`
        FROM books_authors `t_b`
            INNER JOIN (
                SELECT `book_id`, COUNT(`isbn`) `c_e`
                FROM `editions`
                GROUP BY `book_id`
            ) AS `p0`
            ON `t_b`.`book_id` = `p0`.`book_id`
        GROUP BY `t_b`.`au_id`
    ) AS `t2`
    ON `t0`.`au_id` = `t2`.`au_id`
GROUP BY `t0`.`au_id`;
END//
DELIMITER ;

CALL `author_description`();

-- =====================================================================================================================

-- Создать процедуру с параметром по умолчанию
-- и выходным параметром
DROP PROCEDURE IF EXISTS `count_publisher_books`;
DELIMITER //
CREATE PROCEDURE `count_publisher_books`(IN publisher VARCHAR(80) , OUT count_books INT)
BEGIN
    SET publisher = IFNULL(publisher, 'Algodata Infosystems');

    SELECT COUNT(isbn)
    INTO count_books
    FROM editions
    WHERE pub_id = (
        SELECT pub_id
        FROM publishers
        WHERE pub_name = publisher
        )
    GROUP BY pub_id;
END//
DELIMITER ;

CALL `count_publisher_books`('Algodata Infosystems', @M); SELECT @M;
CALL `count_publisher_books`(NULL, @M); SELECT @M;
CALL `count_publisher_books`('New Age Books', @M); SELECT @M;
CALL `count_publisher_books`('Trinity', @M); SELECT @M;