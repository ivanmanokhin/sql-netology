--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.
SELECT concat_ws(' ', last_name, first_name) AS "Customer name",
	address,
	city,
	country
FROM customer c 
LEFT JOIN address a USING(address_id)
INNER JOIN city USING (city_id)
INNER JOIN country USING (country_id);

--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.
SELECT s.store_id AS "ID магазина",
	count(*) AS "Количество покупателей"
FROM store s
INNER JOIN customer c USING (store_id)
GROUP BY s.store_id;

--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.
SELECT s.store_id AS "ID магазина",
	count(*) AS "Количество покупателей"
FROM store s
INNER JOIN customer c USING (store_id)
GROUP BY store_id
HAVING count(*) > 300;

-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.
SELECT s.store_id AS "ID магазина",
	count(*) AS "Количество покупателей",
	ci.city AS "Город",
	concat_ws(' ', st.last_name, st.first_name) AS "Имя сотрудника"
FROM store s
INNER JOIN customer c ON (s.store_id = c.store_id)
INNER JOIN address a ON (s.address_id = a.address_id)
INNER JOIN city ci ON (a.city_id = ci.city_id)
INNER JOIN staff st ON (s.manager_staff_id = st.staff_id)
GROUP BY s.store_id, ci.city, st.last_name, st.first_name
HAVING count(*) > 300;

--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов
SELECT concat_ws(' ', last_name, first_name) AS "Фамилия и имя покупателя",
	count(*) AS "Количество фильмов"
FROM customer c
INNER JOIN rental USING (customer_id)
GROUP BY customer_id 
ORDER BY count(*) DESC
LIMIT 5;

--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма
SELECT concat_ws(' ', last_name, first_name) AS "Фамилия и имя покупателя",
	count(*) AS "Количество фильмов",
	round(sum(amount)) AS "Общая стоимость платежей",
	min(amount) AS "Минимальная стоимость платежа",
	max(amount) AS "Максимальная стоимость платежа"
FROM customer c 
INNER JOIN rental r USING (customer_id)
INNER JOIN payment p USING (rental_id)
GROUP BY (c.customer_id);

--ЗАДАНИЕ №5
--Используя данные из таблицы городов составьте одним запросом всевозможные пары городов таким образом,
 --чтобы в результате не было пар с одинаковыми названиями городов. 
 --Для решения необходимо использовать декартово произведение.
--первый вариант:
SELECT c1.city AS "Город 1",
	c2.city AS "Город 2"
FROM city c1
CROSS JOIN city c2
WHERE c1.city != c2.city;
--второй вариант:
SELECT c1.city AS "Город 1",
	c2.city AS "Город 2"
FROM city c1, city c2
WHERE c1.city != c2.city;

--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date)
--и дате возврата фильма (поле return_date), 
--вычислите для каждого покупателя среднее количество дней, за которые покупатель возвращает фильмы.
SELECT customer_id AS "ID покупателя",
	cast(EXTRACT(epoch FROM avg(age(return_date, rental_date)))/86400 AS numeric(7, 2)) AS "Среднее кол-во дней на возврат"
FROM rental
GROUP BY customer_id
ORDER BY customer_id;

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.
SELECT title AS "Название фильма",
	rating AS "Рейтинг",
	(SELECT "name"
		FROM category c
		WHERE category_id = (SELECT category_id
			FROM film_category fc
			WHERE fc.film_id = f.film_id)) AS "Жанр",
	release_year AS "Год выпуска",
	(SELECT "name"
		FROM "language" l
		WHERE l.language_id = f.language_id) AS "Язык",
	(SELECT count(*)
		FROM rental r
		INNER JOIN inventory i USING (inventory_id)
		WHERE i.film_id = f.film_id
		GROUP BY f.film_id) AS "Количество аренд",
	(SELECT sum(amount)
		FROM payment
		INNER JOIN rental r USING (rental_id)
		INNER JOIN inventory i USING (inventory_id)
		WHERE i.film_id = f.film_id
		GROUP BY f.film_id) AS "Общая стоимость аренды"
FROM film f;

--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью запроса фильмы, которые ни разу не брали в аренду.
SELECT title AS "Название фильма",
	rating AS "Рейтинг",
	(SELECT "name"
		FROM category c
		WHERE category_id = (SELECT category_id
			FROM film_category fc
			WHERE fc.film_id = f.film_id)) AS "Жанр",
	release_year AS "Год выпуска",
	(SELECT "name"
		FROM "language" l
		WHERE l.language_id = f.language_id) AS "Язык",
	COALESCE((SELECT count(*)
		FROM rental r
		INNER JOIN inventory i USING (inventory_id)
		WHERE i.film_id = f.film_id
		GROUP BY f.film_id), 0) AS "Количество аренд",
	(SELECT sum(amount)
		FROM payment
		INNER JOIN rental r USING (rental_id)
		INNER JOIN inventory i USING (inventory_id)
		WHERE i.film_id = f.film_id
		GROUP BY f.film_id) AS "Общая стоимость аренды"
FROM film f
WHERE (SELECT count(*)
		FROM rental r
		INNER JOIN inventory i USING (inventory_id)
		WHERE i.film_id = f.film_id
		GROUP BY f.film_id) IS NULL;

--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".
SELECT staff_id,
	count(*) AS "Количество продаж",
CASE
	WHEN count(*) > 7300 THEN 'Да'
	ELSE 'Нет'
END AS "Премия"
FROM payment p
GROUP BY staff_id;