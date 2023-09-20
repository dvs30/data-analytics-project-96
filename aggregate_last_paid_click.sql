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
where
	medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
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
	SUM(
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

    union all
    select
    to_char(campaign_date,
	'yyyy-mm-dd') as visit_date,
    utm_source,
	utm_medium,
	utm_campaign,
	
	null as revenue,
	null as visitors_count,
	null as leads_count,
	null as purchases_count,
	daily_spent as total_cost
	from vk_ads
	
	union all
	select
	to_char(campaign_date,
	'yyyy-mm-dd') as visit_date,
	utm_source,
	utm_medium,
	utm_campaign,
	null as revenue,
	null as visitors_count,
	null as leads_count,
	null as purchases_count,
	daily_spent as total_cost
	from ya_ads    
)
select
	v.visit_date,
	v.utm_source,
	v.utm_medium,
	v.utm_campaign,
	sum(v.visitors_count) as visitors_count,
	sum(v.total_cost) as total_cost,
	sum(v.leads_count) as leads_count,
	sum(v.purchases_count) as purchases_count,
	sum(v.revenue) as revenue
from
	view2 as v
group by
	v.visit_date,
	v.utm_source,
	v.utm_medium,
	v.utm_campaign
order by
	sum(v.revenue) desc nulls last,
	v.visit_date asc,
	sum(v.visitors_count) desc,
	v.utm_source asc,
	v.utm_medium asc,
	v.utm_campaign asc
limit 15;