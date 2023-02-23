--=============== МОДУЛЬ 2. РАБОТА С БАЗАМИ ДАННЫХ =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите уникальные названия городов из таблицы городов.
SELECT DISTINCT city
FROM city c;

--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания, чтобы запрос выводил только те города,
--названия которых начинаются на “L” и заканчиваются на “a”, и названия не содержат пробелов.
SELECT DISTINCT city
FROM city c
WHERE city LIKE 'L%a'
AND city NOT LIKE '% %';

--ЗАДАНИЕ №3
--Получите из таблицы платежей за прокат фильмов информацию по платежам, которые выполнялись 
--в промежуток с 17 июня 2005 года по 19 июня 2005 года включительно, 
--и стоимость которых превышает 1.00.
--Платежи нужно отсортировать по дате платежа.
SELECT payment_id, payment_date, amount
FROM payment p
WHERE payment_date::DATE BETWEEN '2005-06-17' AND '2005-06-19'
AND amount > 1.00
ORDER BY payment_date;

--ЗАДАНИЕ №4
-- Выведите информацию о 10-ти последних платежах за прокат фильмов.
SELECT payment_id, payment_date, amount
FROM payment p
ORDER BY payment_date DESC
LIMIT 10;

--ЗАДАНИЕ №5
--Выведите следующую информацию по покупателям:
--  1. Фамилия и имя (в одной колонке через пробел)
--  2. Электронная почта
--  3. Длину значения поля email
--  4. Дату последнего обновления записи о покупателе (без времени)
--Каждой колонке задайте наименование на русском языке.
SELECT last_name || ' ' || first_name AS "Фамилия и имя", email AS "Электронная почта",
	LENGTH(email) AS "Длина Email", last_update::DATE AS "Дата"
FROM customer c;

--ЗАДАНИЕ №6
--Выведите одним запросом только активных покупателей, имена которых KELLY или WILLIE.
--Все буквы в фамилии и имени из верхнего регистра должны быть переведены в нижний регистр.
SELECT  LOWER(last_name), LOWER(first_name), active
FROM customer c
WHERE (LOWER(first_name) LIKE 'kelly'
OR LOWER(first_name) LIKE 'willie')
AND active = 1;


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите одним запросом информацию о фильмах, у которых рейтинг "R" 
--и стоимость аренды указана от 0.00 до 3.00 включительно, 
--а также фильмы c рейтингом "PG-13" и стоимостью аренды больше или равной 4.00.
SELECT film_id, title, description, rating, rental_rate 
FROM film f 
WHERE rating = 'R' AND rental_rate <= 3.00
OR rating = 'PG-13' AND rental_rate >= 4.00;

--ЗАДАНИЕ №2
--Получите информацию о трёх фильмах с самым длинным описанием фильма.
SELECT film_id, title, description
FROM film f 
ORDER BY CHAR_LENGTH(description) DESC 
LIMIT 3;

--ЗАДАНИЕ №3
-- Выведите Email каждого покупателя, разделив значение Email на 2 отдельных колонки:
--в первой колонке должно быть значение, указанное до @, 
--во второй колонке должно быть значение, указанное после @.
SELECT customer_id, email, LEFT(email, (STRPOS(email, '@') - 1)) AS "Email before @",
	RIGHT(email, -(STRPOS(email, '@'))) AS "Email after @"
FROM customer c;

--ЗАДАНИЕ №4
--Доработайте запрос из предыдущего задания, скорректируйте значения в новых колонках: 
--первая буква должна быть заглавной, остальные строчными.
SELECT customer_id, email, 
	UPPER(LEFT(email, 1)) || LOWER(RIGHT(LEFT(email, (STRPOS(email, '@')) - 1), - 1)) AS "Email before @",
	UPPER(LEFT(RIGHT(email, -(STRPOS(email, '@'))), 1)) || RIGHT(email, -(STRPOS(email, '@') + 1)) AS "Email after @"
FROM customer c;
