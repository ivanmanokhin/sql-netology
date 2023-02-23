--=============== МОДУЛЬ 4. УГЛУБЛЕНИЕ В SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--База данных: если подключение к облачной базе, то создаёте новую схему с префиксом в --виде фамилии, название должно быть на латинице в нижнем регистре и таблицы создаете --в этой новой схеме, если подключение к локальному серверу, то создаёте новую схему и --в ней создаёте таблицы.
CREATE SCHEMA manokhin_schema;
SET search_path TO manokhin_schema;
--Спроектируйте базу данных, содержащую три справочника:
--· язык (английский, французский и т. п.);
--· народность (славяне, англосаксы и т. п.);
--· страны (Россия, Германия и т. п.).
--Две таблицы со связями: язык-народность и народность-страна, отношения многие ко многим. Пример таблицы со связями — film_actor.
--Требования к таблицам-справочникам:
--· наличие ограничений первичных ключей.
--· идентификатору сущности должен присваиваться автоинкрементом;
--· наименования сущностей не должны содержать null-значения, не должны допускаться --дубликаты в названиях сущностей.
--Требования к таблицам со связями:
--· наличие ограничений первичных и внешних ключей.

--В качестве ответа на задание пришлите запросы создания таблиц и запросы по --добавлению в каждую таблицу по 5 строк с данными.
 
--СОЗДАНИЕ ТАБЛИЦЫ ЯЗЫКИ
CREATE TABLE language(
	language_id serial PRIMARY KEY,
	language_name VARCHAR (25) UNIQUE NOT NULL
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ ЯЗЫКИ
INSERT INTO "language" (language_name)
VALUES
('русский'),
('английский'),
('французский');

--СОЗДАНИЕ ТАБЛИЦЫ НАРОДНОСТИ
CREATE TABLE nation(
	nation_id serial PRIMARY KEY,
	nation_name VARCHAR (25) UNIQUE NOT NULL
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ НАРОДНОСТИ
INSERT INTO nation (nation_name)
VALUES
('славяне'),
('англосаксы'),
('галло-римляне');

--СОЗДАНИЕ ТАБЛИЦЫ СТРАНЫ
CREATE TABLE country(
	country_id serial PRIMARY KEY,
	country_name VARCHAR (25) UNIQUE NOT NULL
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СТРАНЫ
INSERT INTO country(country_name)
VALUES
('Россия'),
('Великобритания'),
('Франция');

--СОЗДАНИЕ ПЕРВОЙ ТАБЛИЦЫ СО СВЯЗЯМИ
CREATE TABLE language_nation(
	language_id INT REFERENCES "language"(language_id),
	nation_id INT REFERENCES nation(nation_id),
	PRIMARY KEY (language_id, nation_id)
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ
INSERT INTO language_nation (language_id, nation_id)
VALUES
(1, 1),
(2, 2),
(3, 3);

--СОЗДАНИЕ ВТОРОЙ ТАБЛИЦЫ СО СВЯЗЯМИ
CREATE TABLE nation_country(
	nation_id INT REFERENCES "language"(language_id),
	country_id INT REFERENCES nation(nation_id),
	PRIMARY KEY (nation_id, country_id)
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ
INSERT INTO nation_country (nation_id, country_id)
VALUES
(1, 1),
(2, 2),
(3, 3);

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============


--ЗАДАНИЕ №1 
--Создайте новую таблицу film_new со следующими полями:
--·   	film_name - название фильма - тип данных varchar(255) и ограничение not null
--·   	film_year - год выпуска фильма - тип данных integer, условие, что значение должно быть больше 0
--·   	film_rental_rate - стоимость аренды фильма - тип данных numeric(4,2), значение по умолчанию 0.99
--·   	film_duration - длительность фильма в минутах - тип данных integer, ограничение not null и условие, что значение должно быть больше 0
--Если работаете в облачной базе, то перед названием таблицы задайте наименование вашей схемы.
CREATE TABLE film_new(
	film_name VARCHAR (255) NOT NULL,
	film_year INTEGER CHECK (film_year > 0),
	film_rental_rate NUMERIC (4, 2) DEFAULT 0.99,
	film_duration INTEGER NOT NULL CHECK (film_duration > 0)
);

--ЗАДАНИЕ №2 
--Заполните таблицу film_new данными с помощью SQL-запроса, где колонкам соответствуют массивы данных:
--·       film_name - array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']
--·       film_year - array[1994, 1999, 1985, 1994, 1993]
--·       film_rental_rate - array[2.99, 0.99, 1.99, 2.99, 3.99]
--·   	  film_duration - array[142, 189, 116, 142, 195]
INSERT INTO film_new (film_name, film_year, film_rental_rate, film_duration)
VALUES
(UNNEST(array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']),
	UNNEST(array[1994, 1999, 1985, 1994, 1993]),
	UNNEST(array[2.99, 0.99, 1.99, 2.99, 3.99]),
	UNNEST(array[142, 189, 116, 142, 195])
);

--ЗАДАНИЕ №3
--Обновите стоимость аренды фильмов в таблице film_new с учетом информации, 
--что стоимость аренды всех фильмов поднялась на 1.41
UPDATE film_new SET film_rental_rate = film_rental_rate + 1.41;

--ЗАДАНИЕ №4
--Фильм с названием "Back to the Future" был снят с аренды, 
--удалите строку с этим фильмом из таблицы film_new
DELETE FROM film_new WHERE film_name = 'Back to the Future';

--ЗАДАНИЕ №5
--Добавьте в таблицу film_new запись о любом другом новом фильме
INSERT INTO film_new -- Умышленно добавил значение без перечисления колонок, т.к. добавляю все и попорядку.
VALUES
('Blade Runner', 1982, 5.5, 117);

--ЗАДАНИЕ №6
--Напишите SQL-запрос, который выведет все колонки из таблицы film_new, 
--а также новую вычисляемую колонку "длительность фильма в часах", округлённую до десятых
SELECT *,
	round(film_duration::numeric/60, 1) AS "Длительность фильма в часах" 
FROM film_new;

--ЗАДАНИЕ №7 
--Удалите таблицу film_new
DROP TABLE film_new;
