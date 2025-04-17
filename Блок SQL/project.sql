-- Создаем 1-ую таблицу и загружаем данные из customer_info.csv

CREATE DATABASE PROJECT;
USE PROJECT;

CREATE TABLE customer_info (
	Id_client INT PRIMARY KEY,
    Total_amount INT,
    Gender CHAR(1),
    Age INT NULL,
    Count_city INT,
    Response_communcation TINYINT,
    Communication_3month TINYINT,
    Tenure INT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customer_info.csv'
INTO TABLE customer_info
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Cоздаем 2-ую таблицу и загружаем данные из transactions_info.csv

CREATE TABLE transactions_info (
	id INT AUTO_INCREMENT PRIMARY KEY,
    date_new DATE,
    Id_check INT,
    ID_client INT,
    Count_products FLOAT,
    Sum_payment FLOAT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions_info.csv'
INTO TABLE transactions_info
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@date_new, Id_check, ID_client, Count_products, Sum_payment)
SET date_new = STR_TO_DATE(@date_new, '%d/%m/%Y');


/* Задание №1. Вывести список клиентов с непрерывной историей за год, т.е. каждый месяц на регулярной основе 
без пропусков за указанный годовой период, средний чек за период с 01.06.2015 по 01.06.2016, 
среднюю сумму покупок за месяц, количество всех операций по клиенту за период
*/

SELECT
    c.ID_client,
    COUNT(DISTINCT DATE_FORMAT(t.date_new, '%Y-%m')) AS Active_months,
    ROUND(SUM(t.Sum_payment) / COUNT(*), 2) AS Avg_check,
    ROUND(SUM(t.Sum_payment) / 12, 2) AS Avg_monthly_spending,
    COUNT(*) AS Total_operations
FROM
    customer_info c
JOIN
    transactions_info t ON c.ID_client = t.ID_client
WHERE
    t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY
    c.ID_client
HAVING
    Active_months = 12;

/* Задание №2. Вывести информацию в разрезе месяцев за период с 01.06.2015 по 01.06.2016:
     a) средняя сумма чека в месяц;
     b) среднее количество операций в месяц;
     c) среднее количество клиентов, которые совершали операции;
     d) долю от общего количества операций за год и долю в месяц от общей суммы операций;
     e) вывести % соотношение M/F/NA в каждом месяце с их долей затрат;
*/

WITH monthly_stats AS (
    SELECT
        DATE_FORMAT(t.date_new, '%Y-%m') AS Месяц,
        COUNT(t.id) AS Количество_операций_в_месяц,
        COUNT(DISTINCT t.ID_client) AS Количество_клиентов_в_месяц,
        AVG(t.Sum_payment) AS Средняя_сумма_чека,
        SUM(t.Sum_payment) AS Сумма_месяца,
        MAX(LAST_DAY(t.date_new)) AS Последний_день_месяца
    FROM transactions_info t
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY DATE_FORMAT(t.date_new, '%Y-%m')
),
year_totals AS (
    SELECT
        COUNT(id) AS Всего_операций_за_год,
        SUM(Sum_payment) AS Всего_сумма_за_год
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
),
gender_stats AS (
    SELECT
        DATE_FORMAT(t.date_new, '%Y-%m') AS Месяц,
        c.Gender,
        COUNT(t.id) AS Операций,
        SUM(t.Sum_payment) AS Затраты
    FROM transactions_info t
    JOIN customer_info c ON t.ID_client = c.ID_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY DATE_FORMAT(t.date_new, '%Y-%m'), c.Gender
)

SELECT
    ms.Месяц,

    -- 1. Средняя сумма чека в месяц
    ROUND(ms.Средняя_сумма_чека, 2) AS `1. Средняя сумма чека в месяц`,

    -- 2. Среднее количество операций в день
    ROUND(ms.Количество_операций_в_месяц / DAY(ms.Последний_день_месяца), 2) AS `2. Среднее количество операций в день`,

    -- 3. Среднее количество клиентов в день
    ROUND(ms.Количество_клиентов_в_месяц / DAY(ms.Последний_день_месяца), 2) AS `3. Среднее количество клиентов в день`,

    -- 4. Доля от общего количества операций и от суммы за год
    ROUND(ms.Количество_операций_в_месяц / yt.Всего_операций_за_год * 100, 2) AS `4. % операций от общего числа`,
    ROUND(ms.Сумма_месяца / yt.Всего_сумма_за_год * 100, 2) AS `4. % суммы от общего объема`,

    -- 5. Гендерное распределение по операциям
    ROUND(100 * SUM(CASE WHEN gs.Gender = 'M' THEN gs.Операций ELSE 0 END) / ms.Количество_операций_в_месяц, 2) AS `5. % операций M`,
    ROUND(100 * SUM(CASE WHEN gs.Gender = 'F' THEN gs.Операций ELSE 0 END) / ms.Количество_операций_в_месяц, 2) AS `5. % операций F`,
    ROUND(100 * SUM(CASE WHEN gs.Gender IS NULL OR gs.Gender NOT IN ('M','F') THEN gs.Операций ELSE 0 END) / ms.Количество_операций_в_месяц, 2) AS `5. % операций NA`,

    -- 5. Гендерное распределение по затратам
    ROUND(100 * SUM(CASE WHEN gs.Gender = 'M' THEN gs.Затраты ELSE 0 END) / ms.Сумма_месяца, 2) AS `5. % затрат M`,
    ROUND(100 * SUM(CASE WHEN gs.Gender = 'F' THEN gs.Затраты ELSE 0 END) / ms.Сумма_месяца, 2) AS `5. % затрат F`,
    ROUND(100 * SUM(CASE WHEN gs.Gender IS NULL OR gs.Gender NOT IN ('M','F') THEN gs.Затраты ELSE 0 END) / ms.Сумма_месяца, 2) AS `5. % затрат NA`

FROM monthly_stats ms
JOIN year_totals yt ON 1=1
LEFT JOIN gender_stats gs ON gs.Месяц = ms.Месяц
GROUP BY
    ms.Месяц, ms.Средняя_сумма_чека, ms.Количество_операций_в_месяц, ms.Количество_клиентов_в_месяц,
    ms.Сумма_месяца, ms.Последний_день_месяца,
    yt.Всего_операций_за_год, yt.Всего_сумма_за_год
ORDER BY ms.Месяц;

/*
  Задание №3. Показать возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, 
  с параметрами суммы и количества операций за весь период, и поквартально - средние показатели и %.
*/

-- Сумма и количество операций по возрастным группам за весь период
WITH age_grouped AS (
    SELECT
        ci.Id_client,
        CASE
            WHEN ci.Age IS NULL THEN 'Без возраста'
            WHEN ci.Age >= 90 THEN '90+'
            ELSE CONCAT(FLOOR(ci.Age / 10) * 10, '-', FLOOR(ci.Age / 10) * 10 + 9)
        END AS Age_Group
    FROM customer_info ci
),
filtered_tx AS (
    SELECT
        t.ID_client,
        t.Sum_payment,
        t.date_new AS tx_date
    FROM transactions_info t
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
),
joined_data AS (
    SELECT
        ag.Age_Group,
        tx.tx_date,
        tx.Sum_payment
    FROM filtered_tx tx
    LEFT JOIN age_grouped ag ON tx.ID_client = ag.Id_client
)

SELECT
    Age_Group,
    REPLACE(FORMAT(COUNT(*), 2), ',', ' ') AS Количество_операций,
    REPLACE(FORMAT(SUM(Sum_payment), 2), ',', ' ') AS Сумма_операций
FROM joined_data
GROUP BY Age_Group
ORDER BY Age_Group;


-- Средние значения и % по кварталам
WITH age_grouped AS (
    SELECT
        ci.Id_client,
        CASE
            WHEN ci.Age IS NULL THEN 'Без возраста'
            WHEN ci.Age >= 90 THEN '90+'
            ELSE CONCAT(FLOOR(ci.Age / 10) * 10, '-', FLOOR(ci.Age / 10) * 10 + 9)
        END AS Age_Group
    FROM customer_info ci
),
filtered_tx AS (
    SELECT
        t.ID_client,
        t.Sum_payment,
        t.date_new AS tx_date
    FROM transactions_info t
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
),
joined_data AS (
    SELECT
        ag.Age_Group,
        tx.tx_date,
        tx.Sum_payment
    FROM filtered_tx tx
    LEFT JOIN age_grouped ag ON tx.ID_client = ag.Id_client
),
month_count AS (
    SELECT
        Age_Group,
        QUARTER(tx_date) AS qtr,
        COUNT(DISTINCT MONTH(tx_date)) AS months_in_quarter
    FROM joined_data
    GROUP BY Age_Group, QUARTER(tx_date)
),
grouped_quarterly AS (
    SELECT
        Age_Group,
        QUARTER(tx_date) AS qtr,
        COUNT(*) AS total_ops,
        SUM(Sum_payment) AS total_sum
    FROM joined_data
    GROUP BY Age_Group, QUARTER(tx_date)
),
quarter_agg AS (
    SELECT
        gq.Age_Group,
        CONCAT('Q', gq.qtr) AS Квартал,
        ROUND(gq.total_ops * 1.0 / mc.months_in_quarter, 2) AS Ср_кол_операций_в_мес,
        ROUND(gq.total_sum / mc.months_in_quarter, 2) AS Ср_сумма_в_мес
    FROM grouped_quarterly gq
    JOIN month_count mc ON gq.Age_Group = mc.Age_Group AND gq.qtr = mc.qtr
),
totals AS (
    SELECT
        QUARTER(tx_date) AS qtr,
        COUNT(*) AS total_ops,
        SUM(Sum_payment) AS total_sum,
        COUNT(DISTINCT MONTH(tx_date)) AS months_in_quarter
    FROM joined_data
    GROUP BY QUARTER(tx_date)
),
total_avg AS (
    SELECT
        CONCAT('Q', qtr) AS Квартал,
        ROUND(total_ops * 1.0 / months_in_quarter, 2) AS total_avg_ops,
        ROUND(total_sum / months_in_quarter, 2) AS total_avg_sum
    FROM totals
)

SELECT
    qa.Age_Group,
    qa.Квартал,
    REPLACE(FORMAT(qa.Ср_кол_операций_в_мес, 2), ',', ' ') AS Ср_кол_операций_в_мес,
    REPLACE(FORMAT(qa.Ср_сумма_в_мес, 2), ',', ' ') AS Ср_сумма_в_мес,
    ROUND(qa.Ср_кол_операций_в_мес / ta.total_avg_ops * 100, 1) AS Доля_от_количества,
    ROUND(qa.Ср_сумма_в_мес / ta.total_avg_sum * 100, 1) AS Доля_от_суммы
FROM quarter_agg qa
JOIN total_avg ta ON qa.Квартал = ta.Квартал
ORDER BY Age_Group, Квартал;
