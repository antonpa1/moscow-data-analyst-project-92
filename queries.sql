--customers_count
select
    count(customer_id) as customers_count  
    -- здесь считаю общее количество покупателей по их id
from customers;

--top_10_total_income
select
    e.first_name || ' ' || e.last_name as seller,  
    -- собираю полное имя продавца в одну строку
    count(s.sales_id) as operations,               
    -- считаю количество продаж (операций)
    floor(sum(p.price * s.quantity)) as income     
    -- считаю выручку по формуле цена * количество
from sales as s
left join employees as e
    on s.sales_person_id = e.employee_id
left join products as p
    on s.product_id = p.product_id  
    -- подтягиваю к продажам данные о продавце и товаре
group by
    e.employee_id,
    e.first_name,
    e.last_name  -- группирую данные по конкретному продавцу
order by
    income desc  -- сортирую продавцов по выручке по убыванию
limit 10;        -- оставляю только топ-10 строк

--lowest_average_income
with seller_avg as (
    select
        e.employee_id,
        e.first_name || ' ' || e.last_name as seller,  
        -- формирую полное имя продавца
        avg(p.price * s.quantity) as avg_income_raw   
        -- считаю среднюю выручку продавца за одну сделку
    from sales as s
    left join employees as e
        on s.sales_person_id = e.employee_id
    left join products as p
        on s.product_id = p.product_id  
        -- присоединяю цену и данные о продавце к продажам
    group by
        e.employee_id,
        e.first_name,
        e.last_name  -- группирую по каждому продавцу
),  -- во временной таблице seller_avg считаю среднюю выручку по каждому продавцу
overall_avg as (
    select
        avg(avg_income_raw) as glob_avg_incom
    from seller_avg
)  -- во временной таблице overall_avg считаю среднюю выручку среди всех продавцов
select
    sa.seller,
    floor(sa.avg_income_raw) as average_income  
    -- округляю среднюю выручку продавца вниз до целого
from seller_avg as sa
left join overall_avg as oa
    on 1 = 1  
    -- соединяю таблицы, так как overall_avg всегда одна строка
where
    sa.avg_income_raw < oa.glob_avg_incom  
    -- оставляю только тех, кто зарабатывает ниже среднего
order by
    average_income;  -- сортирую по средней выручке по возрастанию

--day_of_the_week_income
select
    e.first_name || ' ' || e.last_name as seller, 
-- собираю полное имя продавца
    lower(trim(to_char(s.sale_date, 'day'))) as day_of_week,  
    -- вытаскиваю название дня недели из даты
    floor(sum(p.price * s.quantity)) as income  
    -- считаю суммарную выручку за этот день недели
from sales as s
left join employees as e
    on s.sales_person_id = e.employee_id  
    -- соединяю к продажам данные о продавце
left join products as p
    on s.product_id = p.product_id       
    -- и данные о товаре с ценой
group by
    seller,
    lower(trim(to_char(s.sale_date, 'day'))),
    extract(isodow from s.sale_date)
order by
    extract(isodow from s.sale_date),
    seller;  -- сортирую по номеру дня недели и по имени продавца

--age_groups
select
    age_category,
    count(*) as age_count 
    -- считаю количество покупателей в каждой возрастной группе
from (
    select
        case  -- раскладываю возраст по диапазонам из таблицы customers
            when age between 16 and 25 then '16-25'
            when age between 26 and 40 then '26-40'
            when age > 40 then '40+'
        end as age_category
    from customers
) as c
where
    age_category is not null  
    -- отбрасываю строки, где возраст не попал ни в одну категорию
group by
    age_category  -- объединяю покупателей по возрастным категориям
order by
    case age_category  -- задаю порядок отображения возрастных групп
        when '16-25' then 1
        when '26-40' then 2
        when '40+' then 3
    end;

--customers_by_month
select
    to_char(s.sale_date, 'YYYY-MM') as selling_month,  
    -- привожу дату продажи к формату ГОД-МЕСЯЦ
    count(distinct s.customer_id) as total_customers,  
    -- считаю количество уникальных покупателей в месяце
    floor(sum(p.price * s.quantity)) as income         
    -- считаю выручку за месяц и округляю вниз
from sales as s
left join products as p
    on s.product_id = p.product_id  -- добавляю к продажам цену товара
group by
    to_char(s.sale_date, 'YYYY-MM')  -- группирую данные по месяцу продажи
order by
    selling_month;  -- сортирую месяцы по возрастанию

--special_offer
with sales_cte as (  
-- создаю временную таблицу, чтобы к каждой продаже добавить цену и клиента
    select
        s.sales_id,
        s.customer_id,
        s.sales_person_id,
        s.sale_date,
        p.price,
        row_number() over (
            partition by s.customer_id  -- нумерую покупки внутри каждого покупателя
            order by
                s.sale_date,
                s.sales_id  
                -- сначала по дате, потом по id продажи
        ) as rn
    from sales as s
    left join products as p
        on s.product_id = p.product_id  -- добавляю цену товара к продаже
    where
        p.price = 0  -- беру только акционные покупки с ценой 0
)
select
    c.first_name || ' ' || c.last_name as customer, 
    -- собираю полное имя покупателя
    sc.sale_date,
    e.first_name || ' ' || e.last_name as seller    
-- собираю полное имя продавца
from sales_cte as sc
left join customers as c
    on sc.customer_id = c.customer_id  
    -- подтягиваю данные о покупателе
left join employees as e
    on sc.sales_person_id = e.employee_id  
    -- подтягиваю данные о продавце
where
    sc.rn = 1  
    -- оставляю только первую акционную покупку для каждого покупателя
order by
    c.customer_id,
    sc.sale_date;  -- упорядочиваю по id покупателя и дате покупки

