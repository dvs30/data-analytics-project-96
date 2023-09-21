with raw as (
select
	s.visitor_id,
	s.visit_date,
	s."source" as utm_source,
	s.medium as utm_medium,
	s.campaign as utm_campaign,
	l.lead_id,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	row_number() over (partition by s.visitor_id order by s.visit_date desc) as rn
from
	sessions as s
left join leads as l
on s.visitor_id = l.visitor_id and s.visit_date <= l.created_at
where s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
), view2 as (
select
	to_char(raw.visit_date, 'YYYY-MM-DD') as visit_date,
	raw.utm_source,
	raw.utm_medium,
	raw.utm_campaign,
	count(raw.visitor_id) as visitors_count,
	sum(case
		when raw.lead_id is not null then 1 else 0
		end) as leads_count,
	sum(case
		when raw.closing_reason = 'Успешная продажа' then 1 else 0
		end) as purchases_count,
	sum(raw.amount) as revenue,
	null as total_cost
from raw
where raw.rn = 1
group by
	raw.visit_date,
	raw.utm_source,
	raw.utm_medium,
	raw.utm_campaign
union all
select
	to_char(vk_ads.campaign_date, 'yyyy-mm-dd') as visit_date,
	vk_ads.utm_source,
	vk_ads.utm_medium,
	vk_ads.utm_campaign,
	null as revenue,
	null as visitors_count,
	null as leads_count,
	null as purchases_count,
	daily_spent as total_cost
from vk_ads
union all
select
	to_char(ya_ads.campaign_date, 'yyyy-mm-dd') as visit_date,
	ya_ads.utm_source,
	ya_ads.utm_medium,
	ya_ads.utm_campaign,
	null as revenue,
	null as visitors_count,
	null as leads_count,
	null as purchases_count,
	daily_spent as total_cost
from ya_ads
)
select
	visit_date,
	utm_source,
	utm_medium,
	utm_campaign,
	sum(visitors_count) as visitors_count,
	sum(total_cost) as total_cost,
	sum(leads_count) as leads_count,
	sum(purchases_count) as purchases_count,
	sum(revenue) as revenue
from view2
group by
	visit_date,
	utm_source,
	utm_medium,
	utm_campaign
order by
	sum(revenue) desc nulls last,
	visit_date asc,
	sum(visitors_count) desc,
	utm_source asc,
	utm_medium asc,
	utm_campaign asc
limit 15;
