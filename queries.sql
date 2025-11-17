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

select
to_char(s.sale_date, 'YYYY-MM') as selling_mounth, --приводим дату к нужному формату
count(distinct s.customer_id) as total_customers, -- считаем кол-во уник пользователей
floor(sum(p.price * s.quantity)) as income -- обкругляем сумму выручки
from sales s
join products p on s.product_id = p.product_id --объединяем таблицы чтобы узнать цену товара
group by 
	to_char(s.sale_date, 'YYYY-MM') -- группируем данные по месяцу
order by
	selling_mounth; -- сортируем по месяцу по возрастанию
	
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
	)
select 
	c.first_name ||' '|| c.last_name as custumer, -- имя и фамилия покупателя в одну ячейку
	sc.sale_date,
	e.first_name ||' '|| e.last_name as seller -- имя и фамилия прод в одну ячейку
from sales_cte sc
join customers c on sc.customer_id = c.customer_id  -- данные о покупателе
join employees e on sc.sales_person_id = e.employee_id -- данные о проджавце
where 
	sc.rn = 1 -- берем первую покупку клиента 
	and sc.price = 0 -- и чтобы она была акционной
order by 
	c.customer_id; -- сортируем по id  покупателя