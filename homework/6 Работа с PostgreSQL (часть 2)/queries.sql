--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".
--EXPLAIN ANALYZE --COST: 67.50 TIME: ~0339
SELECT *
FROM film f 
WHERE ARRAY['Behind the Scenes'] <@ special_features;

--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.
--EXPLAIN ANALYZE --COST: 67.50 TIME: ~0340
SELECT *
FROM film f 
WHERE array_position(special_features, 'Behind the Scenes') IS NOT NULL;
--EXPLAIN ANALYZE --COST: 77.50 TIME: ~0285
SELECT *
FROM film f 
WHERE 'Behind the Scenes' = ANY(special_features);

--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.
--EXPLAIN ANALYZE --COST: 693.13 TIME: ~9.115
WITH cte AS (
SELECT *
FROM film f 
WHERE ARRAY['Behind the Scenes'] <@ special_features)
SELECT customer_id,
	concat_ws(' ', first_name, last_name) AS "full_name",
	count(rental_id) AS "rent_count"
FROM customer c
JOIN rental r USING (customer_id)
JOIN inventory i USING (inventory_id)
JOIN cte USING (film_id)
GROUP BY customer_id
ORDER BY customer_id;

--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.
--EXPLAIN ANALYZE --COST: 693.13 TIME: ~9.161
SELECT customer_id,
	concat_ws(' ', first_name, last_name) AS "full_name",
	count(rental_id) AS "rent_count"
FROM customer c
JOIN rental r USING (customer_id)
JOIN inventory i USING (inventory_id)
JOIN (SELECT *
	FROM film f 
	WHERE ARRAY['Behind the Scenes'] <@ special_features) AS t1 USING (film_id)
GROUP BY customer_id
ORDER BY customer_id;

--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления
CREATE MATERIALIZED VIEW bts AS (SELECT customer_id,
	concat_ws(' ', first_name, last_name) AS "full_name",
	count(rental_id) AS "rent_count"
	FROM customer c
	JOIN rental r USING (customer_id)
	JOIN inventory i USING (inventory_id)
	JOIN (SELECT *
	FROM film f 
	WHERE ARRAY['Behind the Scenes'] <@ special_features) AS t1 USING (film_id)
	GROUP BY customer_id
	ORDER BY customer_id) WITH NO DATA;

REFRESH MATERIALIZED VIEW bts;


--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ скорости выполнения запросов
-- из предыдущих заданий и ответьте на вопросы:

--1. Каким оператором или функцией языка SQL, используемых при выполнении домашнего задания, 
--   поиск значения в массиве происходит быстрее
--2. какой вариант вычислений работает быстрее: 
--   с использованием CTE или с использованием подзапроса

--1) Быстрее с использованием any, <@ и array_position дешевле на 10.
--2) В версии postgresql 9 стоимость одинакова, время примерно тоже.



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии
--explain analyze
--select distinct cu.first_name  || ' ' || cu.last_name as name, 
--	count(ren.iid) over (partition by cu.customer_id)
--from customer cu
--full outer join 
--	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
--	from rental r 
--	full outer join 
--		(select *, unnest(f.special_features) as sf_string
--		from inventory i
--		full outer join film f on f.film_id = i.film_id) as inv 
--		on r.inventory_id = inv.inventory_id) as ren 
--	on ren.cid = cu.customer_id 
--where ren.sfs like '%Behind the Scenes%'
--order by count desc

--1) SQL ввиду не оптимизированного запроса, сам попытается его оптимизировать.
--2) Оператор where должен выполнятся в самом конце, но выполняется в самом начале (опять же ввиду неоптимизированности запроса).
--3) Unnest - увеличивает кол-во строк, лучше поиск в массиве с помощью @ или array_position.
--4) Оконная функция лишняя для простого подсчета количества, достаточно агрегатной.
--5) Full Join не нужны, достаточно Left/Inner Join.
--Признаюсь первые два пункта понял из Zoom, по остальным сделал выводы на основе возможности оптимизации запроса.
--Построчное описание:
--Сортировка
--  Ключ сортировки: c.customer_id
--  Метод сортировки: quicksort
--  ->  Агрегирование
--        Ключ агрегации: c.customer_id
--        ->  Объединение по алгоритму hash join
--              Условие объединения таблиц: (r.customer_id = c.customer_id)
--              ->  Объединение по алгоритму hash join
--                    Условие объединения: (i.film_id = f.film_id)
--                    ->  Объединение по алгоритму hash join
--                          Условие объединения:: (r.inventory_id = i.inventory_id)
--                          ->  Полное сканирование таблицы rental r 
--                          ->  Хэширование
--                                Buckets: 8192  Batches: 1  Использованно памяти: 234kB -- не знаю как перевести)
--                                ->  Полное сканирование таблицы inventory i
--                    ->  Хэширование 
--                          Buckets: 1024  Batches: 1  Использованно памяти: 27kB -- не знаю как перевести)
--                          ->  Полное сканирование таблицы film f
--                                Фильтрация: ('{"Behind the Scenes"}'::text[] <@ special_features)
--                                Удаленных строк при фельтрации: 462
--              ->  Хэширование
--                    Buckets: 1024  Batches: 1  Memory Usage: 38kB -- не знаю как перевести)
--                    ->  Полное сканирование таблицы customer c
--Планируемое время исполнения: 0.405 ms
--Фактическое время исполнения: 9.535 ms

--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.
WITH cte_staff AS (
	SELECT p.staff_id,
	film_id,
	title,
	amount,
	payment_date,
	last_name AS "customer_last_name",
	first_name AS "customer_first_name",
	row_number() OVER st_pa AS "row_num"
	FROM payment p
	JOIN rental r USING (rental_id)
	JOIN inventory i USING (inventory_id)
	JOIN film f USING (film_id)
	JOIN customer c ON p.customer_id = c.customer_id
	WINDOW st_pa AS (PARTITION BY p.staff_id ORDER BY payment_date))
SELECT *
FROM cte_staff
WHERE row_num = 1;

--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день
--EXPLAIN analyze
SELECT store_id,
	rental_date,
	count_per_day,
	payment_date,
	payment_per_day
FROM (
	SELECT *, 
		row_number() OVER (PARTITION BY store_id ORDER BY count_per_day desc) AS row_num 
	FROM (
		SELECT store_id,
			rental_date::date,
			count(r.rental_id) OVER (PARTITION BY store_id, rental_date::date) AS "count_per_day"
		FROM rental r 
		JOIN inventory i USING (inventory_id)) AS r0) AS r1
JOIN (
	SELECT *, 
		row_number() OVER (PARTITION BY store_id ORDER BY payment_per_day) AS row_num 
	FROM (
		SELECT store_id,
			payment_date::date,
			sum(amount) OVER (PARTITION BY store_id, payment_date::date) AS "payment_per_day"
		FROM payment p
		JOIN staff s USING (staff_id)) AS p0) AS p1
USING (store_id)
WHERE r1.row_num = 1 AND p1.row_num = 1;
