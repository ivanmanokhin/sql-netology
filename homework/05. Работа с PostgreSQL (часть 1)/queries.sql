--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по сумме платежа от наименьшей к большей
--Пронумеруйте платежи для каждого покупателя по стоимости платежа от наибольших к меньшим 
--так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.
--EXPLAIN analyze
WITH cte_payment AS (
	SELECT customer_id,
	initcap(concat_ws(' ', first_name, last_name)) AS "customer_name",
	payment_id,
	payment_date,
	amount
	FROM payment p
	LEFT JOIN customer c USING (customer_id)
)
SELECT *, 
	row_number() OVER (ORDER BY payment_date) AS "payment_num_all",
	row_number() OVER (PARTITION BY customer_id ORDER BY payment_date) AS "payment_num_cus",
	sum(amount) OVER (PARTITION BY customer_id ORDER BY payment_date, amount) AS "payment_sum",
	dense_rank() OVER (PARTITION BY customer_id ORDER BY amount DESC) AS "high_to_low"
FROM cte_payment cp
ORDER BY customer_id, high_to_low;

--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате.
--EXPLAIN ANALYZE
WITH cte_payment AS (
	SELECT customer_id,
	initcap(concat_ws(' ', first_name, last_name)) AS "customer_name",
	payment_id,
	payment_date,
	amount
	FROM payment p
	LEFT JOIN customer c USING (customer_id)
)
SELECT *,
	sum(amount) OVER (PARTITION BY payment_id) AS "amount_in_windows", -- я не понял зачем стоимость платежа выводить в оконной функции, если она и так есть в таблице, ну вот такой вариант вижу
	lag(amount, 1, 0.) OVER (PARTITION BY customer_id ORDER BY payment_date) AS "previous_amount"
FROM cte_payment cp;

--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.
--EXPLAIN ANALYZE
WITH cte_payment AS (
	SELECT customer_id,
	initcap(concat_ws(' ', first_name, last_name)) AS "customer_name",
	payment_id,
	payment_date,
	amount
	FROM payment p
	LEFT JOIN customer c USING (customer_id)
)
SELECT *,
	amount - lead(amount) OVER (PARTITION BY customer_id ORDER BY payment_date) AS "next_amount_difference"
FROM cte_payment cp;

--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.
--EXPLAIN ANALYZE
WITH cte_payment AS (
	SELECT customer_id,
	initcap(concat_ws(' ', first_name, last_name)) AS "customer_name",
	payment_id,
	payment_date,
	amount
	FROM payment p
	LEFT JOIN customer c USING (customer_id)
)
SELECT customer_id, customer_name, payment_id, last_payment_date, amount
FROM (SELECT *,
	max(payment_date) OVER (PARTITION BY customer_id) AS "last_payment_date"
	FROM cte_payment cp) AS t1
WHERE payment_date = last_payment_date
ORDER BY customer_id;

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.
--EXPLAIN ANALYZE
SELECT staff_id, staff_name, pay_date, com_day, com_total
FROM (SELECT staff_id,
	initcap(concat_ws(' ', first_name, last_name)) AS "staff_name",
	payment_date::date AS "pay_date",
	sum(amount) OVER (PARTITION BY staff_id, payment_date::date ORDER BY staff_id, payment_date::date) AS "com_day",
	sum(amount) OVER (PARTITION BY staff_id ORDER BY staff_id, payment_date::date)  AS "com_total"
	FROM payment p 
	LEFT JOIN staff s USING (staff_id)
	WHERE date_trunc('month', payment_date) = '2005-08-01'
) AS t1
GROUP BY staff_id, staff_name, pay_date, com_day, com_total;

--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку
--EXPLAIN ANALYZE
WITH cte_payment AS (
	SELECT customer_id,
	initcap(concat_ws(' ', first_name, last_name)) AS "customer_name",
	payment_id,
	payment_date,
	amount
	FROM payment p
	LEFT JOIN customer c USING (customer_id)
)
SELECT *
FROM (SELECT *,
	row_number() OVER (PARTITION BY payment_date::date ORDER BY payment_date) AS "payment_num_day"
	FROM cte_payment cp
	WHERE date_trunc('day', payment_date) = '2005-08-20') AS t1
WHERE payment_num_day % 100 = 0;

--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм
--EXPLAIN ANALYZE
WITH cte_rc AS (
SELECT initcap(concat_ws(' ', first_name, last_name)) AS "customer_name", country_id, rent_count, 
	rank() OVER (PARTITION BY country_id ORDER BY rent_count) AS "top"
FROM customer c 
	LEFT JOIN (SELECT DISTINCT customer_id, count(rental_id) OVER (PARTITION BY customer_id) AS "rent_count" FROM rental) t1 ON (c.customer_id = t1.customer_id)
	LEFT JOIN address a USING (address_id)
	JOIN city ci USING (city_id)
),
cte_ca AS (
SELECT initcap(concat_ws(' ', first_name, last_name)) AS "customer_name", country_id, sum_amount, 
	rank() OVER (PARTITION BY country_id ORDER BY sum_amount) AS "top"
FROM customer c 
	LEFT JOIN (SELECT DISTINCT customer_id, sum(amount) OVER (PARTITION BY customer_id) AS "sum_amount" FROM payment) t2 ON (c.customer_id = t2.customer_id)
	LEFT JOIN address a USING (address_id)
	JOIN city ci USING (city_id)
),
cte_lr AS (
SELECT initcap(concat_ws(' ', first_name, last_name)) AS "customer_name", country_id, last_rent, 
	rank() OVER (PARTITION BY country_id ORDER BY last_rent) AS "top"
FROM customer c 
	LEFT JOIN (SELECT DISTINCT customer_id, max(rental_date) OVER (PARTITION BY customer_id) AS "last_rent" FROM rental) t3 ON (c.customer_id = t3.customer_id)
	LEFT JOIN address a USING (address_id)
	JOIN city ci USING (city_id)
)
SELECT country, j1.cn AS "max_films", j2.cn AS "max_amount", j3.cn AS "last_rent"
FROM country c
LEFT JOIN (SELECT country_id, GROUP_CONCAT(customer_name) AS cn 
	FROM cte_rc WHERE top = 1 GROUP BY country_id) AS j1 ON (c.country_id = j1.country_id)
LEFT JOIN (SELECT country_id, GROUP_CONCAT(customer_name) AS cn 
	FROM cte_ca WHERE top = 1 GROUP BY country_id) AS j2 ON (c.country_id = j2.country_id)
LEFT JOIN (SELECT country_id, GROUP_CONCAT(customer_name) AS cn 
	FROM cte_lr WHERE top = 1 GROUP BY country_id) AS j3 ON (c.country_id = j3.country_id)
ORDER BY country;