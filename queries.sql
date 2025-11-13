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
	floor(sa.avg_income_raw) as averange_income --округление
from seller_avg sa
join overall_avg oa on 1 = 1 -- связываем данные без условий
where sa.avg_income_raw < oa.glob_avg_incom 
order by averange_income; --сортировка по возрастанию

select 
	e.first_name || ' ' || e.last_name as seller,  -- склеиваем чтобы получить полное имя продавца
	trim(to_char(s.sale_date, 'Day')) as day_of_week, -- название дня недели
	floor(sum(p.price * s.quantity)) as income -- выпручка прод за день недели 
from sales s
join employees e on s.sales_person_id = e.employee_id 
join products p on s.product_id = p.product_id -- объединяем данные из таблиц
group by e.employee_id, e.first_name, e.last_name, --группирповка по продавцу
	trim(to_char(s.sale_date, 'Day')), -- название дня недели
	extract(dow from s.sale_date)
order by 
	extract(dow from s.sale_date), --извлекаем порядковый номер дни недели
	seller; -- сорировка по порядковому номеру дня недели и продавцу
	

