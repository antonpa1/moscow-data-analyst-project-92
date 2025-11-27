-- customers_count
-- считаю общее количество покупателей по id
select count(customer_id) as customers_count
from customers;

-- top_10_total_income
-- формирую топ-10 продавцов по общей выручке
select
    e.first_name || ' ' || e.last_name as seller,
    count(s.sales_id) as operations,
    floor(sum(p.price * s.quantity)) as income
from sales as s
left join employees as e
    on s.sales_person_id = e.employee_id
left join products as p
    on s.product_id = p.product_id
group by
    e.employee_id,
    e.first_name,
    e.last_name
order by
    income desc
limit 10;

-- lowest_average_income
-- считаю среднюю выручку по каждому продавцу
with seller_avg as (
    select
        e.employee_id,
        e.first_name || ' ' || e.last_name as seller,
        avg(p.price * s.quantity) as avg_income_raw
    from sales as s
    left join employees as e
        on s.sales_person_id = e.employee_id
    left join products as p
        on s.product_id = p.product_id
    group by
        e.employee_id,
        e.first_name,
        e.last_name
)

-- сравниваю среднюю выручку продавца с общей средней по всем
select
    sa.seller,
    floor(sa.avg_income_raw) as average_income
from seller_avg as sa
where
    sa.avg_income_raw < (
        select avg(sa2.avg_income_raw)
        from seller_avg as sa2
    )
order by
    average_income;

-- day_of_the_week_income
-- считаю выручку по дням недели для каждого продавца
select
    e.first_name || ' ' || e.last_name as seller,
    lower(trim(to_char(s.sale_date, 'day'))) as day_of_week,
    floor(sum(p.price * s.quantity)) as income
from sales as s
left join employees as e
    on s.sales_person_id = e.employee_id
left join products as p
    on s.product_id = p.product_id
group by
    seller,
    lower(trim(to_char(s.sale_date, 'day'))),
    extract(isodow from s.sale_date)
order by
    extract(isodow from s.sale_date),
    seller;

-- age_groups
-- считаю количество покупателей в возрастных группах
select
    case
        when age between 16 and 25 then '16-25'
        when age between 26 and 40 then '26-40'
        else '40+'
    end as age_category,
    count(customer_id) as age_count
from customers
group by
    age_category
order by
    age_category;

-- customers_by_month
-- считаю количество уникальных покупателей и выручку по месяцам
select
    to_char(s.sale_date, 'YYYY-MM') as selling_month,
    count(distinct s.customer_id) as total_customers,
    floor(sum(p.price * s.quantity)) as income
from sales as s
left join products as p
    on s.product_id = p.product_id
group by
    to_char(s.sale_date, 'YYYY-MM')
order by
    selling_month;

-- special_offer
-- временная таблица: добавляю цену товара к продаже
-- и нумерую покупки внутри каждого покупателя
with sales_cte as (
    select
        s.sales_id,
        s.customer_id,
        s.sales_person_id,
        s.sale_date,
        p.price,
        row_number() over (
            partition by s.customer_id
            order by
                s.sale_date,
                s.sales_id
        ) as rn
    from sales as s
    left join products as p
        on s.product_id = p.product_id
    where
        p.price = 0
)

-- выбираю первую акционную покупку каждого покупателя
select
    sc.sale_date,
    c.first_name || ' ' || c.last_name as customer,
    e.first_name || ' ' || e.last_name as seller
from sales_cte as sc
left join customers as c
    on sc.customer_id = c.customer_id
left join employees as e
    on sc.sales_person_id = e.employee_id
where
    sc.rn = 1
order by
    c.customer_id,
    sc.sale_date;
	