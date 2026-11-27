PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

INSERT INTO users (first_name, last_name, email, gender, register_date, occupation_id)
VALUES
    ('Алина', 'Сульдина', 'suldina.alina@mail.ru', 'female', date('now'), (SELECT id FROM occupations WHERE name = 'student')),
    ('Егор', 'Тужилкин', 'tuzhilkin.egor@mail.ru', 'male', date('now'), (SELECT id FROM occupations WHERE name = 'student')),
    ('Дарья', 'Федорова', 'fedorova.daria@mail.ru', 'female', date('now'), (SELECT id FROM occupations WHERE name = 'student')),
    ('Евгений', 'Чадин', 'chadin.evgeny@mail.ru', 'male', date('now'), (SELECT id FROM occupations WHERE name = 'student')),
    ('Дмитрий', 'Челнаков', 'chelnokov.07@mail.ru', 'male', date('now'), (SELECT id FROM occupations WHERE name = 'student'));

INSERT INTO movies (title, year)
VALUES
    ('Дюна: Часть вторая', 2024),
    ('Оппенгеймер', 2023),
    ('Джентльмены', 2019);

INSERT INTO movie_genres (movie_id, genre_id)
VALUES
    ((SELECT id FROM movies WHERE title = 'Дюна: Часть вторая' AND year = 2024), (SELECT id FROM genres WHERE name = 'Sci-Fi')),
    ((SELECT id FROM movies WHERE title = 'Оппенгеймер' AND year = 2023), (SELECT id FROM genres WHERE name = 'Drama')),
    ((SELECT id FROM movies WHERE title = 'Джентльмены' AND year = 2019), (SELECT id FROM genres WHERE name = 'Comedy'));

INSERT INTO ratings (user_id, movie_id, rating, timestamp)
VALUES
    ((SELECT id FROM users WHERE email = 'chelnokov.07@mail.ru'), (SELECT id FROM movies WHERE title = 'Дюна: Часть вторая' AND year = 2024), 5.0, strftime('%s', 'now')),
    ((SELECT id FROM users WHERE email = 'chelnokov.07@mail.ru'), (SELECT id FROM movies WHERE title = 'Оппенгеймер' AND year = 2023), 4.5, strftime('%s', 'now')),
    ((SELECT id FROM users WHERE email = 'chelnokov.07@mail.ru'), (SELECT id FROM movies WHERE title = 'Джентльмены' AND year = 2019), 5.0, strftime('%s', 'now'));

COMMIT;
