with lpc as (
select
	s.visitor_id,
	s.visit_date,
	s."source" as utm_source,
	s.medium as utm_medium,
	s.campaign as utm_campaign,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	case 
		when l.created_at < s.visit_date then 'delete' 
	else l.lead_id 
	end as lead_id,
	row_number() over (partition by s.visitor_id order by s.visit_date desc) as rn
from sessions as s
left join leads as l on s.visitor_id = l.visitor_id
where
	s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
	)
select
	visitor_id,
	visit_date,
	utm_source,
	utm_medium,
	utm_campaign,
	lead_id,
	created_at,
	amount,
	closing_reason,
	status_id
from lpc
where (lead_id != 'delete' or lead_id is null) and rn = 1
order by
	amount desc nulls last,
	visit_date asc,
	utm_source asc,
	utm_medium asc,
	utm_campaign asc
limit 10;
