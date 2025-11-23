--customers_count
select count(customer_id) as customers_count -- счтиаем кол-во всех id
from customers;

--top_10_total_income
select 
	e.first_name || ' ' || e.last_name as seller, -- склеиваем чтобы получить полное имя продавца
	count(s.sales_id) as operations, -- считаем кол-во продаж
	floor(sum(p.price * s.quantity)) as income -- считаем выручку
from sales as s
join employees e on s.sales_person_id = e.employee_id 
join products p on s.product_id = p.product_id 
	-- объединяем данные из таблиц
group by e.employee_id, e.first_name, e.last_name --группирповка по продавцу
order by income desc -- сортировка по выручке в обратно порядке
limit 10; -- обозначаем кол-во строк в запросе

--lowest_average_income
with seller_avg as (
select 
	e.employee_id,
	e.first_name || ' ' || e.last_name as seller, -- склеиваем чтобы получить полное имя продавца
	avg(p.price * s.quantity) as avg_income_raw -- средняя выручка каждого продавца
from sales s
join employees e on s.sales_person_id = e.employee_id 
join products p on s.product_id = p.product_id -- объединяем данные из таблиц
group by e.employee_id, e.first_name, e.last_name --группирповка по продавцу
), -- CTE временная таблица для получения средней выручки продавца
overall_avg as (   
	select 
		avg(avg_income_raw) as glob_avg_incom
	from seller_avg
) -- CTE средняя выручка среди всех средних
select 
	sa.seller,
	floor(sa.avg_income_raw) as average_income --округление
from seller_avg sa
join overall_avg oa on 1 = 1 -- связываем данные без условий
where sa.avg_income_raw < oa.glob_avg_incom 
order by average_income; --сортировка по возрастанию

--day_of_the_week_income
select
    e.first_name || ' ' || e.last_name as seller,  -- склеиваем чтобы получить полное имя продавца
    lower(trim(to_char(s.sale_date, 'day'))) as day_of_week,     -- название дня недели
    floor(sum(p.price * s.quantity)) as income -- выпручка прод за день недели 
from sales as s
join employees as e on s.sales_person_id = e.employee_id -- объединяем данные из таблиц
join products as p on s.product_id = p.product_id
group by
    seller,  --группирповка по продавцу
    lower(trim(to_char(s.sale_date, 'day'))), -- название дня недели
    extract(isodow from s.sale_date)
order by
     extract(isodow from s.sale_date),
    seller;  -- сорировка по порядковому номеру дня недели 

--age_groups
select 
	age_category,
	count(*) as age_count --считаем общее кол-во пользователей
from (
	select
		case  --используем CASE для выборки возрастов по условиям из таблицы customers
			when age between 16 and 25 then '16-25'
			when age between 26 and 40 then '26-40'
			when age > 40 then '40+'
		end as age_category
		from customers
		) as c
where age_category is not null -- отсортировываем пустые ячейки
group by age_category  -- группируем по повзрастным категориям
order by 
	case age_category -- выстариваем очередность отображения строк
		when '16-25'  then 1
		when '26-40' then 2
		when '40+' then 3
		end;

--customers_by_month
select
to_char(s.sale_date, 'YYYY-MM') as selling_month, --приводим дату к нужному формату
count(distinct s.customer_id) as total_customers, -- считаем кол-во уник пользователей
floor(sum(p.price * s.quantity)) as income -- обкругляем сумму выручки
from sales s
join products p on s.product_id = p.product_id --объединяем таблицы чтобы узнать цену товара
group by 
	to_char(s.sale_date, 'YYYY-MM') -- группируем данные по месяцу
order by
	selling_month; -- сортируем по месяцу по возрастанию
	
--special_offer	
with sales_cte as (    -- используем временную таблицу для того чтобы подтянуть к каждой продаже клиента и цену
	select s.sales_id,
			s.customer_id,
			s.sales_person_id,
			s.sale_date,
			p.price,
			row_number() over(  -- используем оконную функцию чтобы присвоить каждой строке порядковые номер 
				partition by s.customer_id  -- и разбить на группы продажи для каждого покупателя
				order by s.sale_date, s.sales_id
				) as rn
		from sales s
		join products p on s.product_id = p.product_id -- объединяем таблицы чтобы добавить цену к продаже
		where p.price = 0 -- акционная покупка
	)
select 
	c.first_name ||' '|| c.last_name as customer, -- имя и фамилия покупателя в одну ячейку
	sc.sale_date,
	e.first_name ||' '|| e.last_name as seller -- имя и фамилия прод в одну ячейку
from sales_cte sc
join customers c on sc.customer_id = c.customer_id  -- данные о покупателе
join employees e on sc.sales_person_id = e.employee_id -- данные о проджавце
where 
	sc.rn = 1 -- берем первую покупку клиента 
order by 
	c.customer_id,
	sc.sale_date ; -- сортируем по id покупателя и даты продажи