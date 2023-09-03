with visitors_with_leads as (
select
	s.visitor_id,
	s.visit_date,
	s.source as utm_source,
	s.medium as utm_medium,
	s.campaign as utm_campaign,
	l.lead_id,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	row_number() over (
            partition by s.visitor_id
order by
	case
		when s.medium = 'organic' then 0
		else 1
	end desc,
	s.visit_date desc
        ) as count_m
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
	and s.visit_date <= l.created_at
)
select
	visitor_id, visit_date, utm_source, utm_medium, utm_campaign, lead_id, created_at, amount, closing_reason, status_id
	
from
	visitors_with_leads
where
	count_m = 1
order by
	amount desc nulls last,
	visit_date asc,
	utm_source desc,
	utm_medium desc,
	utm_campaign desc
limit 10;