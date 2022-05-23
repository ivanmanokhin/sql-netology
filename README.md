# Итоговая работа по курсу "SQL и получение данных"
![header](https://user-images.githubusercontent.com/105848432/169823397-da57c3ad-fa14-4c87-abba-e311b1e10ea9.png)
---
### Содержание  
- [Задание 1](#task-1)  
- [Задание 2](#task-2)  
- [Задание 3](#task-3)  
- [Задание 4](#task-4)  
  - [Описание базы данных](#task-4-1)  
  - [Объекты базы данных](#task-4-2)  
  - [Бизнес задачи](#task-4-3)  
- [Задание 5](#task-5)  
  - [Файл с SQL-запросами](queries.sql)

## <a name="task-1"></a> Задание 1: используемый тип подключения  
В работе использовался локальный тип подключения. База данных была развернута из файла avia.backup.  
Скриншот успешного импорта данных:  
![Скриншот импорта](https://user-images.githubusercontent.com/105848432/169804661-e817f17c-93dc-4251-bddb-1d1770e65304.png)

## <a name="task-2"></a> Задание 2: ER-диаграмма  
Скриншот ER-диаграммы из DBeaver`a:  
![Скриншот ER-диаграмма](https://user-images.githubusercontent.com/105848432/170341751-938be5b8-5d00-46d6-a0d6-74025a617575.png)

## <a name="task-3"></a> Задание 3: краткое описания базы данных  
База данных состоит из:  
   * 8 таблиц: aircrafts, airports, boarding_passes, bookings, flights, seats, ticket_flights, tickets
   * 1 представления: flights_v
   * 1 материализованного представления: routes

## <a name="task-4"></a> Задание 4: развернутый анализ базы данных  
### <a name="task-4-1"></a> Описание базы данных  
Предметная область базы данных - авиаперевозки.  
Основной сущностью является бронирование (bookings).  
В одно бронирование можно включить несколько пассажиров, каждому из которых выписывается отдельный билет (tickets). Билет имеет уникальный номер и содержит  информацию о пассажире. Как таковой пассажир не является отдельной сущностью. Как имя,  так и номер документа пассажира могут меняться с течением времени, так что невозможно  однозначно найти все билеты одного человека; для простоты можно считать, что все пассажиры уникальны.  
Билет включает один или несколько перелетов (ticket_flights). Несколько перелетов могут включаться в билет в случаях, когда нет нет прямого рейса, соединяющего пункты отправления и назначения (полет с пересадками), либо когда билет взят «туда и обратно». В схеме данных нет жесткого ограничения, но предполагается, что все билеты в одном бронировании имеют одинаковый набор перелетов.  
Каждый рейс (flights) следует из одного аэропорта (airports) в другой. Рейсы с одним номером имеют одинаковые пункты вылета и назначения, но будут отличаться датой отправления.  
При регистрации на рейс пассажиру выдается посадочный талон (boarding_passes), в котором указано место в самолете. Пассажир может зарегистрироваться только на тот рейс, который есть у него в билете. Комбинация рейса и места в самолете должна быть уникальной, чтобы не допустить выдачу двух посадочных талонов на одно место.  
Количество мест (seats) в самолете и их распределение по классам обслуживания зависит от модели самолета (aircrafts), выполняющего рейс. Предполагается, что каждая модель самолета имеет только одну компоновку салона. Схема данных не контролирует, что места в посадочных талонах соответствуют имеющимся в самолете (такая проверка может быть сделана с использованием табличных триггеров или в приложении).  

### <a name="task-4-2"></a> Объекты базы данных  
**Список отношений**  
| Имя | Тип | Small | Medium | Big | Описание |
| :- | :- | :- | :- | :- | -: |
| aircrafts | таблица | 16 kB | 16 kB | 16 kB | Самолеты |
| airports | таблица | 48 kB | 48 kB | 48 kB | Аэропорты |
| boarding_passes | таблица | 31 MB | 102 MB | 427 MB | Посадочные талоны |
| bookings | таблица | 13 MB | 30 MB | 105 MB | Бронирования |
| flights | таблица | 3 MB | 6 MB | 19 MB | Рейсы |
| flights_v | представление | 0 kb | 0 kB | 0 kB | Рейсы |
| routes | мат. предст. | 136 kB | 136 kB | 136 kB | Маршруты |
| seats | таблица | 88 kB | 88 kB | 88 kB | Места |
| ticket_flights | таблица | 64 MB | 145 MB | 516 MB | Перелеты |
| tickets | таблица | 47 MB | 107 MB | 381 MB | Билеты |

**Таблица bookings.aircrafts**  
Каждая модель воздушного судна идентифицируется своим трехзначным кодом (aircraft_code). Указывается также название модели (model) и максимальная дальность полета в километрах (range).
| Столбец | Тип | Модификаторы | Описание |
| :- | :- | :- | -: |
| aircraft_code | char(3) | NOT NULL | Код самолета, IATA |
| model | text | NOT NULL | Модель самолета |
| range | integer | NOT NULL | Максимальная дальность полета, км |

Индексы:  
1. PRIMARY KEY, btree (aircraft_code)

Ограничения-проверки:  
1. CHECK (range > 0)

Ссылки извне:  
1. TABLE "flights" FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code)
2. TABLE "seats" FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE

**Таблица bookings.airports**  
Аэропорт идентифицируется трехбуквенным кодом (airport_code) и имеет свое имя (airport_name).  
Для города не предусмотрено отдельной сущности, но название (city) указывается и может служить для того, чтобы определить аэропорты одного города. Также указывается широта (longitude), долгота (latitude) и часовой пояс (timezone).  
| Столбец | Тип | Модификаторы | Описание |
| :- | :- | :- | -: |
| airport_code | char(3) | NOT NULL | Код аэропорта |
| airport_name | text | NOT NULL | Название аэропорта |
| city | text | NOT NULL | Город |
| longitude | float | NOT NULL | Координаты аэропорта: долгота |
| latitude | float | NOT NULL | Координаты аэропорта: широта |
| timezone | text | NOT NULL | Временная зона аэропорта |

Индексы:  
1. PRIMARY KEY, btree (airport_code)  

Ссылки извне:  
1. TABLE "flights" FOREIGN KEY (arrival_airport) REFERENCES airports(airport_code)
2. TABLE "flights" FOREIGN KEY (departure_airport) REFERENCES airports(airport_code)

**Таблица bookings.boarding_passes**  
При регистрации на рейс, которая возможна за сутки до плановой даты отправления, пассажиру выдается посадочный талон. Он идентифицируется также, как и перелет — номером билета и номером рейса.  
Посадочным талонам присваиваются последовательные номера (boarding_no) в порядке регистрации пассажиров на рейс (этот номер будет уникальным только в пределах данного рейса). В посадочном талоне указывается номер места (seat_no).  
| Столбец | Тип | Модификаторы | Описание |
| :- | :- | :- | -: |
| ticket_no | char(13) | NOT NULL | Номер билета |
| flight_id | integer | NOT NULL | Идентификатор рейса |
| boarding_no | integer | NOT NULL | Номер посадочного талона |
| seat_no | varchar(4) | NOT NULL | Номер места |

Индексы:  
1. PRIMARY KEY, btree (ticket_no, flight_id)
2. UNIQUE CONSTRAINT, btree (flight_id, boarding_no)
3. UNIQUE CONSTRAINT, btree (flight_id, seat_no)

Ограничения внешнего ключа:  
1. FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights(ticket_no, flight_id)

**Таблица bookings.bookings**  
Пассажир заранее (book_date, максимум за месяц до рейса) бронирует билет себе и, возможно, нескольким другим пассажирам. Бронирование идентифицируется номером (book_ref, шестизначная комбинация букв и цифр).  
Поле total_amount хранит общую стоимость включенных в бронирование перелетов всех пассажиров.  
| Столбец | Тип | Модификаторы | Описание |
| :- | :- | :- | -: |
| book_ref | char(6) | NOT NULL | Номер бронирования |
| book_date | timestamptz | NOT NULL | Дата бронирования |
| total_amount | numeric(10,2) | NOT NULL | Полная сумма бронирования |

Индексы:  
1. PRIMARY KEY, btree (book_ref)

Ссылки извне:  
1. TABLE "tickets" FOREIGN KEY (book_ref) REFERENCES bookings(book_ref)

**Таблица bookings.flights**  
Естественный ключ таблицы рейсов состоит из двух полей — номера рейса (flight_no) и даты отправления (scheduled_departure). Чтобы сделать внешние ключи на эту таблицу компактнее, в качестве первичного используется суррогатный ключ (flight_id).  
Рейс всегда соединяет две точки — аэропорты вылета (departure_airport) и прибытия (arrival_airport). Такое понятие, как «рейс с пересадками» отсутствует: если из одного аэропорта до другого нет прямого рейса, в билет просто включаются несколько необходимых рейсов.  
У каждого рейса есть запланированные дата и время вылета (scheduled_departure) и прибытия (scheduled_arrival). Реальные время вылета (actual_departure) и прибытия (actual_arrival) могут отличаться: обычно не сильно, но иногда и на несколько часов, если рейс задержан.  
Статус рейса (status) может принимать одно из следующих значений:  
* Scheduled  
Рейс доступен для бронирования. Это происходит за месяц до плановой даты вылета;
до этого запись о рейсе не существует в базе данных.
* On Time  
Рейс доступен для регистрации (за сутки до плановой даты вылета) и не задержан.
* Delayed  
Рейс доступен для регистрации (за сутки до плановой даты вылета), но задержан.
* Departed  
Самолет уже вылетел и находится в воздухе.
* Arrived  
Самолет прибыл в пункт назначения.
* Cancelled  
Рейс отменен.

| Столбец | Тип | Модификаторы | Описание |
| :- | :- | :- | -: |
| flight_id | serial | NOT NULL | Идентификатор рейса |
| flight_no | char(6) | NOT NULL | Номер рейса |
| scheduled_departure | timestamptz | NOT NULL | Время вылета по расписанию |
| scheduled_arrival | timestamptz | NOT NULL | Время прилёта по расписанию |
| departure_airport | char(3) | NOT NULL | Аэропорт отправления |
| arrival_airport | char(3) | NOT NULL | Аэропорт прибытия |
| status | varchar(20) | NOT NULL | Статус рейса |
| aircraft_code | char(3) | NOT NULL | Код самолета, IATA |
| actual_departure | timestamptz | | Фактическое время вылета |
| actual_arrival | timestamptz | | Фактическое время прилёта |

Индексы:  
1. PRIMARY KEY, btree (flight_id)
2. UNIQUE CONSTRAINT, btree (flight_no, scheduled_departure)

Ограничения-проверки:  
1. CHECK (scheduled_arrival > scheduled_departure)
2. CHECK ((actual_arrival IS NULL) OR ((actual_departure IS NOT NULL AND actual_arrival IS NOT NULL) AND (actual_arrival > actual_departure)))
3. CHECK (status IN ('On Time', 'Delayed', 'Departed', 'Arrived', 'Scheduled', 'Cancelled'))

Ограничения внешнего ключа:  
1. FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code)
2. FOREIGN KEY (arrival_airport) REFERENCES airports(airport_code)
3. FOREIGN KEY (departure_airport) REFERENCES airports(airport_code)

Ссылки извне:  
1. TABLE "ticket_flights" FOREIGN KEY (flight_id) REFERENCES flights(flight_id)

**Таблица bookings.seats**  
Места определяют схему салона каждой модели. Каждое место определяется своим номером (seat_no) и имеет закрепленный за ним класс обслуживания (fare_conditions) — Economy, Comfort или Business.  
| Столбец | Тип | Модификаторы | Описание |
| :- | :- | :- | -: |
| aircraft_code | char(3) | NOT NULL | Код самолета, IATA |
| seat_no | varchar(4) | NOT NULL | Номер места |
| fare_conditions | varchar(10) | NOT NULL | Класс обслуживания |

Индексы:  
1. PRIMARY KEY, btree (aircraft_code, seat_no)

Ограничения-проверки:  
1. CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business'))

Ограничения внешнего ключа:  
1. FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE

**Таблица bookings.ticket_flights**  
Перелет соединяет билет с рейсом и идентифицируется их номерами. Для каждого перелета указываются его стоимость (amount) и класс обслуживания (fare_conditions).  
| Столбец | Тип | Модификаторы | Описание |
| :- | :- | :- | -: |
| ticket_no | char(13) | NOT NULL | Номер билета |
| flight_id | integer | NOT NULL | Идентификатор рейса |
| fare_conditions | varchar(10) | NOT NULL | Класс обслуживания |
| amount | numeric(10,2) | NOT NULL | Стоимость перелета |

Индексы:  
1. PRIMARY KEY, btree (ticket_no, flight_id)

Ограничения-проверки:  
1. CHECK (amount >= 0)
2. CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business'))

Ограничения внешнего ключа:  
1. FOREIGN KEY (flight_id) REFERENCES flights(flight_id)
2. FOREIGN KEY (ticket_no) REFERENCES tickets(ticket_no)

Ссылки извне:  
1. TABLE "boarding_passes" FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights(ticket_no, flight_id)

**Таблица bookings.tickets**  
Билет имеет уникальный номер (ticket_no), состоящий из 13 цифр.  
Билет содержит идентификатор пассажира (passenger_id) — номер документа, удостоверяющего личность, — его фамилию и имя (passenger_name) и контактную информацию (contact_date).  
Ни идентификатор пассажира, ни имя не являются постоянными (можно поменять паспорт, можно сменить фамилию), поэтому однозначно найти все билеты одного и того же пассажира невозможно.  
| Столбец | Тип | Модификаторы | Описание |
| :- | :- | :- | -: |
| ticket_no | char(13) | NOT NULL | Номер билета |
| book_ref | char(6) | NOT NULL | Номер бронирования |
| passenger_id | varchar(20) | NOT NULL | Идентификатор пассажира |
| passenger_name | text | NOT NULL | Имя пассажира |
| contact_data | jsonb | | Контактные данные пассажира |

Индексы:  
1. PRIMARY KEY, btree (ticket_no)

Ограничения внешнего ключа:  
1. FOREIGN KEY (book_ref) REFERENCES bookings(book_ref)

Ссылки извне:  
1. TABLE "ticket_flights" FOREIGN KEY (ticket_no) REFERENCES tickets(ticket_no)

**Представление "bookings.flights_v"**  
Над таблицей flights создано представление flights_v, содержащее дополнительную информацию:
* расшифровку данных об аэропорте вылета  
(departure_airport, departure_airport_name, departure_city),
* расшифровку данных об аэропорте прибытия  
(arrival_airport, arrival_airport_name, arrival_city),
* местное время вылета  
(scheduled_departure_local, actual_departure_local),
* местное время прибытия  
(scheduled_arrival_local, actual_arrival_local),
* продолжительность полета  
(scheduled_duration, actual_duration).

| Столбец | Тип | Описание |
| :- | :- | -: |
| flight_id | integer | Идентификатор рейса |
| flight_no | char(6) | Номер рейса |
| scheduled_departure | timestamptz | Время вылета по расписанию |
| scheduled_departure_local | timestamp | Время вылета по расписанию, местное время в пункте отправления |
| scheduled_arrival | timestamptz | Время прилёта по расписанию |
| scheduled_arrival_local | timestamp | Время прилёта по расписанию, местное время в пункте прибытия |
| scheduled_duration | interval | Планируемая продолжительность полета |
| departure_airport | char(3) | Код аэропорта отправления |
| departure_airport_name | text | Название аэропорта отправления |
| departure_city | text | Город отправления |
| arrival_airport | char(3) | Код аэропорта прибытия |
| arrival_airport_name | text | Название аэропорта прибытия |
| arrival_city | text | Город прибытия |
| status | varchar(20) | Статус рейса |
| aircraft_code | char(3) | Код самолета, IATA |
| actual_departure | timestamptz | Фактическое время вылета |
| actual_departure_local | timestamp | Фактическое время вылета, местное время в пункте отправления |
| actual_arrival | timestamptz | Фактическое время прилёта |
| actual_arrival_local | timestamp | Фактическое время прилёта, местное время в пункте прибытия |
| actual_duration | interval | Фактическая продолжительность полета |

**Материализованное представление bookings.routes**  
Таблица рейсов содержит избыточность: из нее можно было бы выделить информацию о маршруте (номер рейса, аэропорты отправления и назначения), которая не зависит от конкретных дат рейсов.  
Именно такая информация и составляет материализованное представление routes.  
| Столбец | Тип | Описание |
| :- | :- | -: |
| flight_no | char(6) | Номер рейса |
| departure_airport | char(3) | Код аэропорта отправления |
| departure_airport_name | text | Название аэропорта отправления |
| departure_city | text | Город отправления |
| arrival_airport | char(3) | Код аэропорта прибытия |
| arrival_airport_name | text | Название аэропорта прибытия |
| arrival_city | text | Город прибытия |
| aircraft_code | char(3) | Код самолета, IATA |
| duration | interval | Продолжительность полета |
| days_of_week | integer[] | Дни недели, когда выполняются рейсы |

### <a name="task-4-3"></a> Бизнес задачи  
База данных может использоваться для задач:
1. Анализа загрузки направлений перелетов, эффективности рейсов
2. Анализа загрузки терминалов аэропортов, пассажиропотока
3. Получения статистики по пассажирам, популярности тех или иных классов обслуживания
4. Расчет требуемого количества топлива для перелетов
5. Прогнозирования требуемого количества рейсов, моделей самолетов на направлениях, в зависимости от конкретного времени (время года, дни недели и т.д.)

## <a name="task-5"></a> Задание 5: описание SQL-запросов  
Запросы, описание логики и ответы находятся в [файле с SQL-запросами](queries.sql).
