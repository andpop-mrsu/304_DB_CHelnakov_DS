#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Для каждой пары должны быть указаны имена пользователей и название фильма, который они ценили. В списке оставить первые 100 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT u1.name AS user1, u2.name AS user2, m.title FROM ratings r1 JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id JOIN users u1 ON r1.user_id = u1.id JOIN users u2 ON r2.user_id = u2.id JOIN movies m ON r1.movie_id = m.id ORDER BY m.title, user1, user2 LIMIT 100;"
echo " "

echo "2. Найти 10 самых старых оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH oldest_per_user AS (SELECT r.user_id, r.movie_id, r.rating, r.timestamp, ROW_NUMBER() OVER (PARTITION BY r.user_id ORDER BY r.timestamp ASC, r.id ASC) AS rn FROM ratings r) SELECT m.title, u.name, o.rating, date(o.timestamp, 'unixepoch') AS rating_date FROM oldest_per_user o JOIN users u ON o.user_id = u.id JOIN movies m ON o.movie_id = m.id WHERE o.rn = 1 ORDER BY o.timestamp ASC, o.user_id ASC LIMIT 10;"
echo " "

echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В зависимости от рейтинга в колонке 'Рекомендуем' для фильмов должно быть написано 'Да' или 'Нет'."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH movie_avg AS (SELECT m.id, m.title, m.year, AVG(r.rating) AS avg_rating FROM movies m JOIN ratings r ON m.id = r.movie_id GROUP BY m.id, m.title, m.year), bounds AS (SELECT MAX(avg_rating) AS max_r, MIN(avg_rating) AS min_r FROM movie_avg) SELECT ma.title, ma.year, ROUND(ma.avg_rating, 2) AS avg_rating, CASE WHEN ma.avg_rating = b.max_r THEN 'Да' ELSE 'Нет' END AS Рекомендуем FROM movie_avg ma CROSS JOIN bounds b WHERE ma.avg_rating = b.max_r OR ma.avg_rating = b.min_r ORDER BY ma.year, ma.title;"
echo " "

echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-мужчины в период с 2011 по 2014 год."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT COUNT(*) AS ratings_count, ROUND(AVG(r.rating), 2) AS avg_rating FROM ratings r JOIN users u ON r.user_id = u.id WHERE u.gender = 'male' AND CAST(strftime('%Y', r.timestamp, 'unixepoch') AS INTEGER) BETWEEN 2011 AND 2014;"
echo " "

echo "5. Составить список фильмов с указанием средней оценки и количества пользователей, которые их оценили. Полученный список отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT m.title, m.year, ROUND(AVG(r.rating), 2) AS avg_rating, COUNT(DISTINCT r.user_id) AS users_count FROM movies m LEFT JOIN ratings r ON m.id = r.movie_id GROUP BY m.id, m.title, m.year ORDER BY m.year, m.title LIMIT 20;"
echo " "

echo "6. Определить самый распространенный жанр фильма и количество фильмов в этом жанре. Отдельную таблицу для жанров не использовать, жанры нужно извлекать из таблицы movies."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres(movie_id, genre, rest) AS (SELECT id, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, 1, instr(genres, '|') - 1) ELSE genres END, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, instr(genres, '|') + 1) ELSE '' END FROM movies WHERE genres IS NOT NULL AND genres != '' AND genres != '(no genres listed)' UNION ALL SELECT movie_id, CASE WHEN instr(rest, '|') > 0 THEN substr(rest, 1, instr(rest, '|') - 1) ELSE rest END, CASE WHEN instr(rest, '|') > 0 THEN substr(rest, instr(rest, '|') + 1) ELSE '' END FROM split_genres WHERE rest != '') SELECT genre, COUNT(DISTINCT movie_id) AS movies_count FROM split_genres GROUP BY genre ORDER BY movies_count DESC LIMIT 1;"
echo " "

echo "7. Вывести список из 10 последних зарегистрированных пользователей в формате 'Фамилия Имя|Дата регистрации' (сначала фамилия, потом имя)."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT substr(name, instr(name, ' ') + 1) || ' ' || substr(name, 1, instr(name, ' ') - 1) || '|' || register_date AS user_info FROM users ORDER BY register_date DESC LIMIT 10;"
echo " "

echo "8. С помощью рекурсивного CTE определить, на какие дни недели приходился ваш день рождения в каждом году."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE birthdays(yr, bdate) AS (SELECT 2007, '2007-01-18' UNION ALL SELECT yr + 1, printf('%04d-01-18', yr + 1) FROM birthdays WHERE yr < CAST(strftime('%Y', 'now') AS INTEGER)) SELECT bdate AS birthday_date, CASE strftime('%w', bdate) WHEN '0' THEN 'Воскресенье' WHEN '1' THEN 'Понедельник' WHEN '2' THEN 'Вторник' WHEN '3' THEN 'Среда' WHEN '4' THEN 'Четверг' WHEN '5' THEN 'Пятница' WHEN '6' THEN 'Суббота' END AS weekday FROM birthdays;"
echo " "
