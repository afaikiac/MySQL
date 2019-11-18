DROP DATABASE bookbiz;
CREATE DATABASE bookbiz;

CREATE TABLE publishers
(
    pub_id   INT AUTO_INCREMENT,
    pub_name VARCHAR(80) NOT NULL,
    city     VARCHAR(45) NULL,
    state    VARCHAR(45) NULL,

    CONSTRAINT pk_publishers
        PRIMARY KEY (pub_id)
);

CREATE TABLE books
(
    book_id INT AUTO_INCREMENT,
    title   VARCHAR(80) NOT NULL,

    CONSTRAINT pk_book
        PRIMARY KEY (book_id)
);

CREATE TABLE editions
(
    isbn        CHAR(13),
    book_id     INT,
    ed          INT NULL,
    pub_id      INT,
    num_pages   INT NULL,
    circulation BIGINT(15) NUll,
    date_stamp  DATE

    CONSTRAINT pk_editions
        PRIMARY KEY (isbn),
    CONSTRAINT pk_editions_unique
        UNIQUE (isbn),
    CONSTRAINT fk_editions_book
        FOREIGN KEY (book_id) REFERENCES books (book_id)
            ON DELETE CASCADE,
    CONSTRAINT fk_editions_pub
        FOREIGN KEY (pub_id) REFERENCES publishers (pub_id)
            ON DELETE SET NULL
);

CREATE TABLE authors
(
    au_id    INT AUTO_INCREMENT,
    au_lname VARCHAR(40) NOT NULL,
    au_fname VARCHAR(20) NOT NULL,

    CONSTRAINT pk_authors
        PRIMARY KEY (au_id)
);

CREATE TABLE books_authors
(
    book_id INT,
    au_id   INT,

    CONSTRAINT fk_books_authors_bookb
        FOREIGN KEY (book_id) REFERENCES books (book_id)
            ON DELETE CASCADE,
    CONSTRAINT fk_books_authors_au
        FOREIGN KEY (au_id) REFERENCES authors (au_id)
            ON DELETE CASCADE
);