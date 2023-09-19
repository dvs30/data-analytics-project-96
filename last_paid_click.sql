/*Task 2*/
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
	case
		when lpc.created_at < lpc.visit_date then 'delete'
		else lead_id
	end as lead_id,
	lpc.created_at,
	lpc.amount,
	lpc.closing_reason,
	lpc.status_id
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
	utm_campaign asc
limit 10;