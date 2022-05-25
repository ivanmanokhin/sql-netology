SET search_path TO bookings;

--1. В каких городах больше одного аэропорта?
--
--Из таблицы airports (используя агрегатную функцию count() и оператор GROUP BY) получаем данные
--о количестве аэропортов в городах. Группировка по city.
--Используя полученные значения отфильтровываем данные по количеству
--аэропортов в городах (используя оператор HAVING и оператор сравнения >).
--Результат: Москва (3), Ульяновск (2).
SELECT city,
	count(*) AS "airports_count"
FROM airports a
GROUP BY city
HAVING count(*) > 1;

--2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
--
--Для получения скалярного значения о самолете с максимальной дальностью перелета
--применяется функция max(), используется таблица aircrafts.
--Далее результат этого подзапроса передаем в условие по которому определяем
--aircraft_code самолета(ов) с максимальной дальностью перелета.
--Получение списка значений требуется в связи с тем, что самолет с максимальной дальностью
--перелета может быть не один.
--Вложенные подзапросы применяем в условии, по которому значение aircraft_code из таблицы flights
--сравнивается с полученным списком значений (оператор IN).
--В результате получаем список аэропортов вылета, на которых есть рейсы,
--где используются самолеты с максимальной дальностью перелета.
--Результат: SVX, DME, PEE, VKO, OVB, SVO, AER.
SELECT departure_airport AS "airports"
FROM flights f
WHERE aircraft_code IN (
	SELECT aircraft_code 
	FROM aircrafts a
	WHERE "range" = (
		SELECT max("range")  
		FROM aircrafts a
		)
	)
GROUP BY departure_airport;

--3. Вывести 10 рейсов с максимальным временем задержки вылета.
--
--Из таблицы flights по условию где значение атрибута actual_departure не равно null (т.е. вылетевшие рейсы)
--получаем данные о flight_id, 
--и результат разности (в часах) между фактическим временем вылета и планируемым временем вылета,
--вычисленные значения сортируем по убыванию (DESC).
--Ограничиваем вывод первых 10 строк используя оператор LIMIT.
--Результат: рейсы 14750, 1408, 24253, 22778, 2852, 21684, 11426, 9891, 13645, 4781.
SELECT flight_id, 
	actual_departure - scheduled_departure AS "departure_delay"
FROM flights f
WHERE actual_departure IS NOT null
ORDER BY departure_delay DESC
LIMIT 10;

--4. Были ли брони, по которым не были получены посадочные талоны?
--
--Для получения информации о купленных билетах к таблице bookings присоединим (по методу LEFT JOIN)
--таблицу tickets по условию (ON) b.book_ref = t.book_ref (номер бронирования).
--Для получения информации о посадочных талонах к таблице tickets присоединяем (по методу LEFT JOIN)
--таблицу boarding_passes по условию t.ticket_no = bp.ticket_no (номер билета).
--Метод LEFT JOIN использовался для того, чтобы сохранить данные в таблице "слева".
--Далее отфильтровываем данные (оператор WHERE) по признаку отсутствия посадочного талона (значение null в столбце boarding_no).
--Для получения уникальных номеров бронирования используем оператор DISTINCT по столбцу book_ref.
--Для подсчета количества уникальных броней не имеющих посадочных талонов используем агрегатную функцию count().
--Результат: 91388 уникальных броней не имеющих посадочных талонов.
SELECT count(DISTINCT b.book_ref) AS "book_count"
FROM bookings b
LEFT JOIN tickets t ON b.book_ref = t.book_ref
LEFT JOIN boarding_passes bp ON t.ticket_no = bp.ticket_no
WHERE boarding_no IS null;

--5. Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день.
--Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня.
--
--Для разделения логики запроса выведем получение данных о количестве мест в самолетах в
--обобщенное табличное выражение (CTE).
--В CTE из таблицы seats используя агрегацию (GROUP BY и агрегатную функцию count())
--получаем количество мест в каждом самолете. Группировка по столбцу aircraft_code.
--Данные из таблицы boarding_passes о занятых местах на рейсах получим подзапросом.
--Для этого будем использовать агрегатную функцию count(). Группировка по столбцу flight_id.
--Соединяем таблицу flights с результатом подзапроса, в котором получаем данные о занятых местах и
--c СTE cte_seats_count.
--В результате соединения получаем данные о рейсе, коде самолета, количестве мест в самолете,
--занятом количестве мест в самолете, вычисляемом значении (проценте) свободных мест на рейсе,
--аэропорте вылета, фактическом времени вылета и результат оконной функции
--по сумме занятых мест в пределах аэропорта вылета и фактического времени вылета 
--(приведенном к типу данных date для отброса временных значений),
--а также накопительным итогом по фактическому времени вылета.
--Сортируем полученные данные по полю flight_id в порядке возрастания.
WITH cte_seats_count AS (SELECT aircraft_code,
	count(seat_no) AS "seats_count"
	FROM seats
	GROUP BY aircraft_code
)
SELECT DISTINCT f.flight_id,
	f.aircraft_code,
	seats_count,
	occ_seats,
	(seats_count - occ_seats) * 100 / seats_count AS "free_seats_perc",
	departure_airport,
	actual_departure,
	sum(occ_seats) OVER (PARTITION BY departure_airport, actual_departure::date ORDER BY actual_departure) AS "fly_out_pass"
FROM flights f
JOIN (SELECT flight_id, 
	count(seat_no) AS "occ_seats"
	FROM boarding_passes 
	GROUP BY flight_id) AS t1 ON f.flight_id = t1.flight_id
JOIN cte_seats_count csc ON f.aircraft_code = csc.aircraft_code
ORDER BY flight_id;

--6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.
--
--Из таблицы flights получаем уникальные (оператор DISTINCT) значения aircraft_code.
--Для получения процентов: применяя оконную функцию считаем количество строк в пределах
--каждого aircraft_code, умножаем это значение на 100 и делим на результат работы
--оконной функции для всей таблицы.
--Округляем полученные значений до целочисленного значения использую функцию round.
--Результат: 733 (4), 319 (4), CN1 (28), 763 (4), 321 (6), CR2 (27), SU9 (26), 773 (2)
SELECT DISTINCT aircraft_code,
	round((count(*) OVER (PARTITION BY aircraft_code) * 100 / count(*) OVER ()::numeric)) AS "perc_of_total"
FROM flights f;

--7. Были ли города, в которые можно добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
--
--Для разделения логики создаем 2 обобщенных табличных выражения.
--В первом, из таблицы ticket_flights, по условию, где fare_conditions = 'Economy',
--используя агрегацию, получаем данные о минимальной стоимости перелета на рейсе в эконом классе.
--Группируем по flight_id.
--Во втором, те же действия, только меняем условия на fare_conditions = 'Business',
--используя агрегацию, получаем данные о минимальной стоимости перелета на рейсе
--в бизнес-классе. Группируем по flight_id.
--В основном запросе, используя INNER JOIN, присоединяем таблицу flights к airports.
--Присоединяем таблицу flights к CTE cte_eco_costs и к CTE cte_bus_costs.
--Отфильтровываем данные по условию, где цена из таблицы со стоимостью эконом класса выше,
--чем цена бизнес-класса.
--Из полученных данных выбираем номер рейса и город.
--Результат: рейсов с условием где цена бизнес-класса была бы дешевле - нет.
WITH cte_eco_costs AS (SELECT flight_id,
	min(amount) AS "cost_eco"
FROM ticket_flights tf
WHERE fare_conditions = 'Economy'
GROUP BY flight_id
),
cte_bus_costs AS (SELECT flight_id,
	min(amount) AS "cost_bus"
FROM ticket_flights tf
WHERE fare_conditions = 'Business'
GROUP BY flight_id
)
SELECT f.flight_id,
	city
FROM flights f
JOIN airports a ON f.arrival_airport  = a.airport_code 
JOIN cte_bus_costs cbc ON f.flight_id = cbc.flight_id
JOIN cte_eco_costs cec ON f.flight_id = cec.flight_id
WHERE cost_eco > cost_bus;

--8. Между какими городами нет прямых рейсов?
--
--Создаем два представления.
--В первом, используя декартово произведение получаем пары всех возможных городов.
--Выполняем фильтрацию, при которой в итоговую выборку не попадут одинаковые значения. 
--С помощью оператора DISTINCT выбираем только уникальные города.
--Во втором, таблицу flights присоединяем к таблице airports, 
--делаем это два раза, т.к. город нужен как для аэропорта отправления, так и для прибытия.
--Выполняем фильтрация, при которой в итоговую выборку не попадут города с одинаковым названием.
--С помощью оператора DISTINCT выбираем только уникальные города.
--В основном запросе, используя пересечение множеств, соединим таблицу с существующими маршрутами.
--Пересечение множеств используется для тех случаев, в которых может быть направление только в
--одну сторону, выполняя условие, такой маршрут будет считаться прямым рейсом.
--Далее, с помощью разности множеств находим города, между которыми нет прямых рейсов.
CREATE VIEW all_routes AS (
	SELECT DISTINCT a1.city AS "departure_city", 
	a2.city AS "arrival_city"
	FROM airports a1, airports a2
	WHERE a1.city != a2.city);
CREATE VIEW exist_routes AS (
	SELECT DISTINCT a1.city AS "departure_city",
		a2.city AS "arrival_city"
	FROM flights f
	JOIN airports a1 ON f.departure_airport = a1.airport_code 
	JOIN airports a2 ON f.arrival_airport = a2.airport_code
	WHERE a1.city != a2.city);
SELECT departure_city, arrival_city FROM all_routes ca 
EXCEPT
(SELECT departure_city, arrival_city FROM exist_routes er
UNION
SELECT arrival_city, departure_city FROM exist_routes er);

--9. Вычислите расстояние между аэропортами, связанными прямыми рейсами,
--сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы *
--
--Для разделения логики используется обобщенное табличное выражение, в котором соединяются
--таблицы flights и airports. Таблица airports присоединяется два раза для того, чтобы
--получить координаты как для аэропорта вылета, так и для аэропорта прилета, . Соединение по
--методу INNER JOIN.
--В результате получаем данные, в которых есть модель воздушного судна, аэропорт вылета,
--аэропорт прибытия, координаты аэропортов и вычисленную с применением с использованием координат
--аэропортов, среднего радиуса земного шара и функций: acos, cos, cos, radians, дистанцию между аэропортами.
--Дистанция, с помощью функции round округлена до 2-х знаков после запятой.
--В основном запросе соединяем обобщенное табличное выражении с таблицей aircrafts.
--Таблица aircrafts используется для получения данных о максимальной дальности перелета для каждой 
--модели воздушного судна.
--В результирующей выборке получаем: модель воздушного судна, аэропорт вылета, аэропорт прибытия,
--дистанцию между аэропортами, и (с использованием функции CASE) проверяем, что растояние между аэропортами
--меньше, чем максимальная дальность перелета воздушного судна.
WITH cte_distance AS (SELECT DISTINCT aircraft_code,
	departure_airport,
	arrival_airport,
	a1.longitude, a1.latitude, a2.longitude, a2.latitude,
	round(6371 * acos(cos(radians(a2.latitude))
		* cos(radians(a1.latitude))
		* cos(radians(a1.longitude) - radians(a2.longitude))
		+ sin(radians(a2.latitude))
		* sin(radians(a1.latitude)))::numeric, 2) AS distance
FROM flights f
JOIN airports a1 ON f.departure_airport = a1.airport_code
JOIN airports a2 ON f.arrival_airport = a2.airport_code
)
SELECT cd.aircraft_code,
	departure_airport,
	arrival_airport,
	distance, 
	CASE 
		WHEN distance < "range" THEN True
		WHEN distance > "range" THEN False
		ELSE NULL
	END AS "dis_less_range"
FROM cte_distance cd
JOIN aircrafts a ON cd.aircraft_code = a.aircraft_code;
