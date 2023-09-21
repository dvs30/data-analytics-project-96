/* Общее количество посещений платформы за месяц*/
select
	to_char(visit_date, 'month') as month,
	count(visitor_id) as visitors_count
from sessions s
group by to_char(visit_date, 'month');

/* Общее количество посещений платформы по дням*/
with view as(
select
	to_char(date_trunc('day',visit_date), 'YYYY-MM-DD') as date,
	count(visitor_id) as visitors_count
from sessions s
group by to_char(date_trunc('day',visit_date), 'YYYY-MM-DD') 
)
select date, sum(visitors_count) from view
group by date
order by date;

/* Общее количество посещений платформы по неделям*/
with view as(
select
	to_char(date_trunc('week',visit_date), 'YYYY-MM-DD') as week_date,
	count(visitor_id) as visitors_count
from sessions s
group by to_char(date_trunc('week',visit_date), 'YYYY-MM-DD')
)
select week_date, sum(visitors_count) from view
group by week_date
order by week_date;

/*  Общий топ (10) по количеству визитов по источникам (source) */
with view as (
select
	"source",
	count(visitor_id) as visitors_count
from sessions
group by source)
select
	"source",
	sum(visitors_count) as total
from view
group by "source"
order by sum(visitors_count) desc
limit 10;

/*  Общий топ (10) по количеству визитов по источникам (medium) */
with view as (
select
	medium,
	count(visitor_id) as visitors_count
from sessions
group by medium)
select
	medium,
	sum(visitors_count) as total
from view
group by medium
order by sum(visitors_count) desc
limit 10;

/* Количество уникальных посетителей за месяц*/
select
	to_char(visit_date,
	'month') as month,
	count(distinct visitor_id) as uniq_visitors_count
from sessions s
group by to_char(visit_date,
	'month');

/* Количество уникальных посетителей. 
 * Топ 4 по источникам*/
with view as (
select
	"source",
	count(distinct visitor_id) as visitors_count
from sessions
group by source)
select
	"source",
	sum(visitors_count) as total
from view
group by "source"
order by sum(visitors_count) desc
limit 4;

/* Количество уникальных посетителей.
 * Распределение по дням */
with view as(
select
	date_trunc('day', visit_date) as visit_date,
	case
		when source in ('google', 'yandex', 'vk') then "source"
		else 'other'
	end as "source",
	count(distinct visitor_id) as visitors_count
from
	sessions
group by date_trunc('day', visit_date),	"source"
)
select visit_date, "source", sum(visitors_count) as total from view
group by "source", visit_date
order by date_trunc('day', visit_date),	sum(visitors_count) desc;


/* Коэффициент липучести */
with mau as (
select
	count(distinct visitor_id) as mau
from sessions),
pre_dau as (
select
	date_trunc('day', visit_date) as visit_date,
	count(distinct visitor_id) as daily_visitor_count
from sessions
group by date_trunc('day', visit_date)
), dau as (
select
	percentile_cont(0.5) within group (
	order by daily_visitor_count) as dau
from pre_dau
)
select
	round(dau.dau :: INTEGER * 100.0 / mau.mau, 2) as sticky_factor
from dau, mau;


/* Количество лидов и успешных лидов*/
with view as(
select
	closing_reason,
	case
		when amount > 0 then 1
		else 0
	end as leed_amount,
	to_char(date_trunc('day', created_at), 'YYYY-MM-DD') as date
from
	leads
order by date
)
select
	count(leed_amount) as total,
	sum(leed_amount) as purchases_count,
	count(leed_amount) - sum(leed_amount) as not_purchases_count
from view;

/* Конверсия */
with view as(
select
	closing_reason,
	case
		when amount > 0 then 1
		else 0
	end as leed_amount,
	to_char(date_trunc('day', created_at), 'YYYY-MM-DD') as date
from
	leads
order by date
), view_1 as(
select
	count(leed_amount) as total,
	sum(leed_amount) as purchases_count,
	count(leed_amount) - sum(leed_amount) as not_purchases_count
from view
)
select
purchases_count * 100 / total as conversion
from view_1;

/* Доход */
with view as(
select
	amount,
	closing_reason,
	case
		when amount > 0 then 1
		else 0
	end as leed_amount, to_char(date_trunc('day', created_at), 'YYYY-MM-DD') as date
from
	leads
order by date
)
select
	sum(amount) as total_amount
from view;


/* Средний доход */
with view as(
select
	amount,
	closing_reason,
	case
		when amount > 0 then 1
		else 0
	end as leed_amount, 
	to_char(date_trunc('day', created_at), 'YYYY-MM-DD') as date
from
	leads
order by date
)
select
	round(avg(amount), 2) as avg_amount
from view;

/* Общий расход */
with view as(
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	daily_spent
from
	vk_ads
union all
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	daily_spent
from
	ya_ads  
)
select
	sum(daily_spent) as total_spent
from
	view;

/* Общий расход по дням */
with view as(
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	daily_spent
from
	vk_ads
union all
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	daily_spent
from
	ya_ads  
),
view_1 as(
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	sum(daily_spent) as total_spent
from
	view
group by
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date
        )
select
to_char(date_trunc('day', campaign_date), 'YYYY-MM-DD') as date,
	sum(total_spent) as total_spent
from
	view_1
group by to_char(date_trunc('day', campaign_date), 'YYYY-MM-DD')
order by to_char(date_trunc('day', campaign_date), 'YYYY-MM-DD');

/* Общий расход по source */
with view as(
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	daily_spent
from
	vk_ads
union all
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	daily_spent
from
	ya_ads  
),
view_1 as(
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	sum(daily_spent) as total_spent
from
	view
group by
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date
        )
select
	utm_source,
	sum(total_spent) as total_spent
from
	view_1
group by utm_source;

/* Общий расход по medium */
with view as(
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	daily_spent
from
	vk_ads
union all
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	daily_spent
from
	ya_ads  
),
view_1 as(
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	sum(daily_spent) as total_spent
from
	view
group by
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date
        )
select
	utm_medium,
	utm_source ,
	sum(total_spent) as total_spent
from
	view_1
group by utm_medium, utm_source;

/* Общий расход по campaign */
with view as(
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	daily_spent
from
	vk_ads
union all
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	daily_spent
from
	ya_ads  
),
view_1 as(
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	sum(daily_spent) as total_spent
from
	view
group by
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date
        )
select
	utm_campaign,
	sum(total_spent) as total_spent
from
	view_1
group by utm_campaign
order by sum(total_spent) desc;

/* Общий расход по content */
with view as(
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	daily_spent
from
	vk_ads
union all
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	daily_spent
from
	ya_ads  
),
view_1 as(
select
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date,
	sum(daily_spent) as total_spent
from
	view
group by
	campaign_name,
	utm_source,
	utm_medium,
	utm_campaign,
	utm_content,
	campaign_date
        )
select
	utm_content,
	sum(total_spent) as total_spent
from
	view_1
group by utm_content
order by sum(total_spent) desc;

/* Расчет воронки */

with view as (
select
	s.visitor_id,
	s.visit_date,
	s."source" as utm_source,
	s.medium as utm_medium,
	s.campaign as utm_campaign,
	l.lead_id ,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	row_number()
            over (partition by s.visitor_id order by visit_date desc) as rn
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
	and visit_date <= created_at
),

view2 as(
select 
	to_char(visit_date, 'YYYY-MM-DD') as visit_date,
	utm_source,
    utm_medium,
    utm_campaign,
    count(visitor_id) as visitors_count,
    sum(
    	case 
	    	when lead_id is not null then 1
	    	else 0 
    	end) as leads_count,
	sum(
		case
			when closing_reason = 'Успешная продажа' or status_id = 142 then 1
			else 0
		end) as purchases_count,
	sum(amount) as revenue,
	null as total_cost
from view
where view.rn = 1 
group by
	visit_date,
	utm_source,
    utm_medium,
    utm_campaign
), view3 as(
select
'attendance' as metric,
sum(visitors_count) as total
from view2
union all
select
	'leads' as metric,
sum(leads_count) as total
from
	view2
	union all
select
	'success_leads' as metric,
sum(purchases_count) as total
from
	view2
)
select * from view3;

/* LPC */

with lpc as (
select
	s.visitor_id,
	s.visit_date,
	s."source",
	s.medium,
	s.campaign,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	case
		when l.created_at < s.visit_date then 'delete'
		else lead_id
	end as lead_id,
	row_number()
            over (partition by s.visitor_id
order by
	s.visit_date desc)
        as rn
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
where
	s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
)
select
	lpc.visitor_id,
	lpc.visit_date,
	lpc.source as utm_source,
	lpc.medium as utm_medium,
	lpc.campaign as utm_campaign,
	lpc.created_at,
	lpc.amount,
	lpc.closing_reason,
	lpc.status_id,
	case
		when lpc.created_at < lpc.visit_date then 'delete'
		else lead_id
	end as lead_id
from
	lpc
where
	(lpc.lead_id != 'delete'
		or lpc.lead_id is null)
	and lpc.rn = 1
order by
	lpc.amount desc nulls last,
	lpc.visit_date asc,
	utm_source asc,
	utm_medium asc,
	utm_campaign asc;

/* CPU, CPL, CPPU, ROI*/

/* CPU */
with lpc as(
select
	s.visitor_id,
	s.visit_date,
	s."source",
	s.medium,
	s.campaign,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	case
		when l.created_at < s.visit_date then 'delete'
		else lead_id
	end as lead_id,
	row_number()
            over (partition by s.visitor_id
order by
	s.visit_date desc)
        as rn
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
where
	s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

view as (
    select
	lpc.visitor_id,
	lpc.visit_date,
	lpc.source as utm_source,
	lpc.medium as utm_medium,
	lpc.campaign as utm_campaign,
	lpc.created_at,
	lpc.amount,
	lpc.closing_reason,
	lpc.status_id,
	case
		when lpc.created_at < lpc.visit_date then 'delete'
		else lead_id
	end as lead_id
from
	lpc
where
	(lpc.lead_id != 'delete'
		or lpc.lead_id is null)
	and lpc.rn = 1
),

amount as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(visitor_id) as visitors_count,
        sum(case when lead_id is not null then 1 else 0 end) as leads_count,
        sum(
            case
                when
                    closing_reason = 'Успешная продажа' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count,
        sum(amount) as revenue
    from view
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_1 as (
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from vk_ads
    union all
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from ya_ads
),

cost as (
    select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from view_1
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_2 as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        null as revenue,
        null as visitors_count,
        null as leads_count,
        null as purchases_count,
        total_cost
    from cost
    union all
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        revenue,
        visitors_count,
        leads_count,
        purchases_count,
        null as total_cost
    from amount
),
view_3 as (
select
    utm_source,
    utm_campaign,
    sum(coalesce(visitors_count, 0)) as visitors_count,
    sum(coalesce(total_cost, 0)) as total_cost
from view_2
group by
    utm_source,
    utm_campaign
order by total_cost desc
)
select 
utm_source,
utm_campaign,
    CASE WHEN visitors_count = 0 THEN NULL ELSE total_cost / visitors_count END AS cpu
FROM view_3
order by cpu desc

/* CPL */
with lpc as(
select
	s.visitor_id,
	s.visit_date,
	s."source",
	s.medium,
	s.campaign,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	case
		when l.created_at < s.visit_date then 'delete'
		else lead_id
	end as lead_id,
	row_number()
            over (partition by s.visitor_id
order by
	s.visit_date desc)
        as rn
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
where
	s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

view as (
    select
	lpc.visitor_id,
	lpc.visit_date,
	lpc.source as utm_source,
	lpc.medium as utm_medium,
	lpc.campaign as utm_campaign,
	lpc.created_at,
	lpc.amount,
	lpc.closing_reason,
	lpc.status_id,
	case
		when lpc.created_at < lpc.visit_date then 'delete'
		else lead_id
	end as lead_id
from
	lpc
where
	(lpc.lead_id != 'delete'
		or lpc.lead_id is null)
	and lpc.rn = 1
),

amount as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(visitor_id) as visitors_count,
        sum(case when lead_id is not null then 1 else 0 end) as leads_count,
        sum(
            case
                when
                    closing_reason = 'Успешная продажа' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count,
        sum(amount) as revenue
    from view
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_1 as (
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from vk_ads
    union all
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from ya_ads
),

cost as (
    select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from view_1
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_2 as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        null as revenue,
        null as visitors_count,
        null as leads_count,
        null as purchases_count,
        total_cost
    from cost
    union all
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        revenue,
        visitors_count,
        leads_count,
        purchases_count,
        null as total_cost
    from amount
),
view_3 as (
select
    utm_source,
    utm_medium,
    utm_campaign,
    sum(coalesce(total_cost, 0)) as total_cost,
    sum(coalesce(leads_count, 0)) as leads_count
from view_2
group by
    utm_source,
    utm_medium,
    utm_campaign
order by total_cost desc
),
view_4 as (
select 
utm_source,
utm_campaign,
    CASE WHEN leads_count = 0 THEN NULL ELSE total_cost / leads_count END AS cpl
FROM view_3
)
select * from view_4
where cpl is not null
order by cpl desc

/* CPPU */
with lpc as(
select
	s.visitor_id,
	s.visit_date,
	s."source",
	s.medium,
	s.campaign,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	case
		when l.created_at < s.visit_date then 'delete'
		else lead_id
	end as lead_id,
	row_number()
            over (partition by s.visitor_id
order by
	s.visit_date desc)
        as rn
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
where
	s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

view as (
    select
	lpc.visitor_id,
	lpc.visit_date,
	lpc.source as utm_source,
	lpc.medium as utm_medium,
	lpc.campaign as utm_campaign,
	lpc.created_at,
	lpc.amount,
	lpc.closing_reason,
	lpc.status_id,
	case
		when lpc.created_at < lpc.visit_date then 'delete'
		else lead_id
	end as lead_id
from
	lpc
where
	(lpc.lead_id != 'delete'
		or lpc.lead_id is null)
	and lpc.rn = 1
),

amount as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(visitor_id) as visitors_count,
        sum(case when lead_id is not null then 1 else 0 end) as leads_count,
        sum(
            case
                when
                    closing_reason = 'Успешная продажа' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count,
        sum(amount) as revenue
    from view
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_1 as (
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from vk_ads
    union all
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from ya_ads
),

cost as (
    select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from view_1
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_2 as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        null as revenue,
        null as visitors_count,
        null as leads_count,
        null as purchases_count,
        total_cost
    from cost
    union all
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        revenue,
        visitors_count,
        leads_count,
        purchases_count,
        null as total_cost
    from amount
),
view_3 as (
select
    utm_source,
    utm_medium,
    utm_campaign,
    sum(coalesce(total_cost, 0)) as total_cost,
    sum(coalesce(purchases_count, 0)) as purchases_count
from view_2
group by
    utm_source,
    utm_medium,
    utm_campaign
order by total_cost desc
),
view_4 as (
select 
utm_source,
utm_campaign,
    CASE WHEN purchases_count = 0 THEN NULL ELSE total_cost / purchases_count END AS cppu
FROM view_3
)
select * from view_4
where cppu is not null
order by cppu desc


/* ROI > 0 */
with lpc as(
select
	s.visitor_id,
	s.visit_date,
	s."source",
	s.medium,
	s.campaign,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	case
		when l.created_at < s.visit_date then 'delete'
		else lead_id
	end as lead_id,
	row_number()
            over (partition by s.visitor_id
order by
	s.visit_date desc)
        as rn
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
where
	s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

view as (
    select
	lpc.visitor_id,
	lpc.visit_date,
	lpc.source as utm_source,
	lpc.medium as utm_medium,
	lpc.campaign as utm_campaign,
	lpc.created_at,
	lpc.amount,
	lpc.closing_reason,
	lpc.status_id,
	case
		when lpc.created_at < lpc.visit_date then 'delete'
		else lead_id
	end as lead_id
from
	lpc
where
	(lpc.lead_id != 'delete'
		or lpc.lead_id is null)
	and lpc.rn = 1
),

amount as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(visitor_id) as visitors_count,
        sum(case when lead_id is not null then 1 else 0 end) as leads_count,
        sum(
            case
                when
                    closing_reason = 'Успешная продажа' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count,
        sum(amount) as revenue
    from view
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_1 as (
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from vk_ads
    union all
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from ya_ads
),

cost as (
    select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from view_1
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_2 as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        null as revenue,
        null as visitors_count,
        null as leads_count,
        null as purchases_count,
        total_cost
    from cost
    union all
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        revenue,
        visitors_count,
        leads_count,
        purchases_count,
        null as total_cost
    from amount
),
view_3 as (
select
    utm_source,
    utm_medium,
    utm_campaign,
    sum(coalesce(total_cost, 0)) as total_cost,
    sum(coalesce(revenue, 0)) as revenue
from view_2
group by
    utm_source,
    utm_medium,
    utm_campaign
order by total_cost desc
),
view_4 as (
select 
utm_source,
utm_campaign,
    CASE WHEN total_cost = 0 THEN NULL ELSE ((revenue - total_cost) / total_cost) * 100 END AS roi
FROM view_3
)
select * from view_4
where roi is not null and roi > 0
order by roi desc


/* ROI < 0 */
with lpc as(
select
	s.visitor_id,
	s.visit_date,
	s."source",
	s.medium,
	s.campaign,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	case
		when l.created_at < s.visit_date then 'delete'
		else lead_id
	end as lead_id,
	row_number()
            over (partition by s.visitor_id
order by
	s.visit_date desc)
        as rn
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
where
	s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

view as (
    select
	lpc.visitor_id,
	lpc.visit_date,
	lpc.source as utm_source,
	lpc.medium as utm_medium,
	lpc.campaign as utm_campaign,
	lpc.created_at,
	lpc.amount,
	lpc.closing_reason,
	lpc.status_id,
	case
		when lpc.created_at < lpc.visit_date then 'delete'
		else lead_id
	end as lead_id
from
	lpc
where
	(lpc.lead_id != 'delete'
		or lpc.lead_id is null)
	and lpc.rn = 1
),

amount as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(visitor_id) as visitors_count,
        sum(case when lead_id is not null then 1 else 0 end) as leads_count,
        sum(
            case
                when
                    closing_reason = 'Успешная продажа' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count,
        sum(amount) as revenue
    from view
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_1 as (
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from vk_ads
    union all
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from ya_ads
),

cost as (
    select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from view_1
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_2 as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        null as revenue,
        null as visitors_count,
        null as leads_count,
        null as purchases_count,
        total_cost
    from cost
    union all
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        revenue,
        visitors_count,
        leads_count,
        purchases_count,
        null as total_cost
    from amount
),
view_3 as (
select
    utm_source,
    utm_medium,
    utm_campaign,
    sum(coalesce(total_cost, 0)) as total_cost,
    sum(coalesce(revenue, 0)) as revenue
from view_2
group by
    utm_source,
    utm_medium,
    utm_campaign
order by total_cost desc
),
view_4 as (
select 
utm_source,
utm_campaign,
    CASE WHEN total_cost = 0 THEN NULL ELSE ((revenue - total_cost) / total_cost) * 100 END AS roi
FROM view_3
)
select * from view_4
where roi is not null and roi < 0
order by roi desc

/* Окупаемые каналы */
with lpc as(
select
	s.visitor_id,
	s.visit_date,
	s."source",
	s.medium,
	s.campaign,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	case
		when l.created_at < s.visit_date then 'delete'
		else lead_id
	end as lead_id,
	row_number()
            over (partition by s.visitor_id
order by
	s.visit_date desc)
        as rn
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
where
	s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

view as (
    select
	lpc.visitor_id,
	lpc.visit_date,
	lpc.source as utm_source,
	lpc.medium as utm_medium,
	lpc.campaign as utm_campaign,
	lpc.created_at,
	lpc.amount,
	lpc.closing_reason,
	lpc.status_id,
	case
		when lpc.created_at < lpc.visit_date then 'delete'
		else lead_id
	end as lead_id
from
	lpc
where
	(lpc.lead_id != 'delete'
		or lpc.lead_id is null)
	and lpc.rn = 1
),

amount as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(visitor_id) as visitors_count,
        sum(case when lead_id is not null then 1 else 0 end) as leads_count,
        sum(
            case
                when
                    closing_reason = 'Успешная продажа' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count,
        sum(amount) as revenue
    from view
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_1 as (
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from vk_ads
    union all
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from ya_ads
),

cost as (
    select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from view_1
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_2 as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        null as revenue,
        null as visitors_count,
        null as leads_count,
        null as purchases_count,
        total_cost
    from cost
    union all
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        revenue,
        visitors_count,
        leads_count,
        purchases_count,
        null as total_cost
    from amount
),
view_3 as (
select
    utm_source,
    utm_medium,
    utm_campaign,
    sum(coalesce(total_cost, 0)) as total_cost,
    sum(coalesce(revenue, 0)) as revenue
from view_2
group by
    utm_source,
    utm_medium,
    utm_campaign
order by total_cost desc
),
view_4 as (
select 
    *,
    CASE WHEN total_cost = 0 THEN NULL ELSE ((revenue - total_cost) / total_cost) * 100 END AS roi
FROM view_3
)
select
*,
revenue - total_cost as net
from view_4
where revenue - total_cost > 0 and roi is not null
order by revenue - total_cost desc;

/* Неокупаемые каналы */
with lpc as(
select
	s.visitor_id,
	s.visit_date,
	s."source",
	s.medium,
	s.campaign,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	case
		when l.created_at < s.visit_date then 'delete'
		else lead_id
	end as lead_id,
	row_number()
            over (partition by s.visitor_id
order by
	s.visit_date desc)
        as rn
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
where
	s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

view as (
    select
	lpc.visitor_id,
	lpc.visit_date,
	lpc.source as utm_source,
	lpc.medium as utm_medium,
	lpc.campaign as utm_campaign,
	lpc.created_at,
	lpc.amount,
	lpc.closing_reason,
	lpc.status_id,
	case
		when lpc.created_at < lpc.visit_date then 'delete'
		else lead_id
	end as lead_id
from
	lpc
where
	(lpc.lead_id != 'delete'
		or lpc.lead_id is null)
	and lpc.rn = 1
),

amount as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(visitor_id) as visitors_count,
        sum(case when lead_id is not null then 1 else 0 end) as leads_count,
        sum(
            case
                when
                    closing_reason = 'Успешная продажа' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count,
        sum(amount) as revenue
    from view
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_1 as (
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from vk_ads
    union all
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from ya_ads
),

cost as (
    select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from view_1
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_2 as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        null as revenue,
        null as visitors_count,
        null as leads_count,
        null as purchases_count,
        total_cost
    from cost
    union all
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        revenue,
        visitors_count,
        leads_count,
        purchases_count,
        null as total_cost
    from amount
),
view_3 as (
select
    utm_source,
    utm_medium,
    utm_campaign,
    sum(coalesce(total_cost, 0)) as total_cost,
    sum(coalesce(revenue, 0)) as revenue
from view_2
group by
    utm_source,
    utm_medium,
    utm_campaign
order by total_cost desc
),
view_4 as (
select 
    *,
    CASE WHEN total_cost = 0 THEN NULL ELSE ((revenue - total_cost) / total_cost) * 100 END AS roi
FROM view_3
)
select
*,
revenue - total_cost as net
from view_4
where revenue - total_cost < 0 and roi is not null
order by revenue - total_cost desc;

/* Неокупаемые каналы */
with lpc as(
select
	s.visitor_id,
	s.visit_date,
	s."source",
	s.medium,
	s.campaign,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	case
		when l.created_at < s.visit_date then 'delete'
		else lead_id
	end as lead_id,
	row_number()
            over (partition by s.visitor_id
order by
	s.visit_date desc)
        as rn
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
where
	s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

view as (
    select
	lpc.visitor_id,
	lpc.visit_date,
	lpc.source as utm_source,
	lpc.medium as utm_medium,
	lpc.campaign as utm_campaign,
	lpc.created_at,
	lpc.amount,
	lpc.closing_reason,
	lpc.status_id,
	case
		when lpc.created_at < lpc.visit_date then 'delete'
		else lead_id
	end as lead_id
from
	lpc
where
	(lpc.lead_id != 'delete'
		or lpc.lead_id is null)
	and lpc.rn = 1
),

amount as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(visitor_id) as visitors_count,
        sum(case when lead_id is not null then 1 else 0 end) as leads_count,
        sum(
            case
                when
                    closing_reason = 'Успешная продажа' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count,
        sum(amount) as revenue
    from view
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_1 as (
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from vk_ads
    union all
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from ya_ads
),

cost as (
    select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from view_1
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_2 as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        null as revenue,
        null as visitors_count,
        null as leads_count,
        null as purchases_count,
        total_cost
    from cost
    union all
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        revenue,
        visitors_count,
        leads_count,
        purchases_count,
        null as total_cost
    from amount
),
view_3 as (
select
    utm_source,
    utm_medium,
    utm_campaign,
    sum(coalesce(total_cost, 0)) as total_cost,
    sum(coalesce(revenue, 0)) as revenue
from view_2
group by
    utm_source,
    utm_medium,
    utm_campaign
order by total_cost desc
),
view_4 as (
select 
    *,
    CASE WHEN total_cost = 0 THEN NULL ELSE ((revenue - total_cost) / total_cost) * 100 END AS roi
FROM view_3
)
select
*,
revenue - total_cost as net
from view_4
where revenue = 0 and total_cost > 0
order by revenue - total_cost desc;

/* total result */
with lpc as(
select
	s.visitor_id,
	s.visit_date,
	s."source",
	s.medium,
	s.campaign,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	case
		when l.created_at < s.visit_date then 'delete'
		else lead_id
	end as lead_id,
	row_number()
            over (partition by s.visitor_id
order by
	s.visit_date desc)
        as rn
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
where
	s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

view as (
    select
	lpc.visitor_id,
	lpc.visit_date,
	lpc.source as utm_source,
	lpc.medium as utm_medium,
	lpc.campaign as utm_campaign,
	lpc.created_at,
	lpc.amount,
	lpc.closing_reason,
	lpc.status_id,
	case
		when lpc.created_at < lpc.visit_date then 'delete'
		else lead_id
	end as lead_id
from
	lpc
where
	(lpc.lead_id != 'delete'
		or lpc.lead_id is null)
	and lpc.rn = 1
),

amount as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(visitor_id) as visitors_count,
        sum(case when lead_id is not null then 1 else 0 end) as leads_count,
        sum(
            case
                when
                    closing_reason = 'Успешная продажа' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count,
        sum(amount) as revenue
    from view
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_1 as (
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from vk_ads
    union all
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from ya_ads
),

cost as (
    select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from view_1
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

view_2 as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        null as revenue,
        null as visitors_count,
        null as leads_count,
        null as purchases_count,
        total_cost
    from cost
    union all
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        revenue,
        visitors_count,
        leads_count,
        purchases_count,
        null as total_cost
    from amount
),
view_3 as (
select
    utm_source,
    utm_medium,
    utm_campaign,
    sum(coalesce(purchases_count, 0)) as purchases_count,
    sum(coalesce(visitors_count, 0)) as visitors_count,
    sum(coalesce(leads_count, 0)) as leads_count,
    sum(coalesce(total_cost, 0)) as total_cost,
    sum(coalesce(revenue, 0)) as revenue
from view_2
group by
    utm_source,
    utm_medium,
    utm_campaign
order by total_cost desc
),
view_4 as (
select
	*,
    CASE WHEN visitors_count = 0 THEN NULL ELSE total_cost / visitors_count END AS cpu,
    CASE WHEN leads_count = 0 THEN NULL ELSE total_cost / leads_count END AS cpl,
    CASE WHEN purchases_count = 0 THEN NULL ELSE total_cost / purchases_count END AS cppu,
    CASE WHEN total_cost = 0 THEN NULL ELSE ((revenue - total_cost) / total_cost) * 100 END AS roi
FROM view_3
)
select
sum(visitors_count) as total_visitors,
sum(total_cost) as total_cost,
sum(leads_count) as total_leads,
sum(purchases_count) as total_purchases,
sum(revenue) as total_revenue,
round(sum(total_cost) / sum(visitors_count), 2) as total_cpu,
round(sum(total_cost) / sum(leads_count), 2) as total_cpl,
round(sum(total_cost) / sum(purchases_count), 2) as total_cppu,
round((sum(revenue) - sum(total_cost)) * 100 / sum(total_cost), 2) as total_roi
from view_4;