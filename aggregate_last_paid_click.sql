with view as (
select
	s.visitor_id,
	to_char(s.visit_date,
	'yyyy-mm-dd') as visit_date,
	s."source" as utm_source,
	s.medium as utm_medium,
	s.campaign as utm_campaign,
	l.lead_id ,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	case
		when l.closing_reason = 'успешная продажа'
		or l.status_id = 142
                then 1
		else 0
	end as purchases,
	row_number()
            over (partition by s.visitor_id
order by
	visit_date desc)
        as rn
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
	and visit_date <= created_at
where
	medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

vk_view as (
select
	utm_source,
	utm_medium,
	utm_campaign,
	to_char(campaign_date,
	'yyyy-mm-dd') as vk_campaign_date,
	sum(daily_spent) as total_vk_spent
from
	vk_ads
group by
	to_char(campaign_date,
	'yyyy-mm-dd'),
	utm_source,
	utm_medium,
	utm_campaign
),

ya_view as (
select
	utm_source,
	utm_medium,
	utm_campaign,
	to_char(campaign_date,
	'yyyy-mm-dd') as ya_campaign_date,
	sum(daily_spent) as total_ya_spent
from
	ya_ads
group by
	to_char(campaign_date,
	'yyyy-mm-dd'),
	utm_source,
	utm_medium,
	utm_campaign
)
select
	v.visit_date,
	count(v.visitor_id) as visitors_count,
	v.utm_source,
	v.utm_medium,
	v.utm_campaign,
	coalesce(total_ya_spent,
	0) + coalesce(total_vk_spent,
	0) as total_cost,
	count(v.lead_id) as leads_count,
	sum(v.purchases) as purchases_count,
	sum(coalesce(v.amount, 0)) as revenue
from
	view as v
left join vk_view as vk
    on
	v.visit_date = vk.vk_campaign_date
	and v.utm_source = vk.utm_source
	and v.utm_medium = vk.utm_medium
	and v.utm_campaign = vk.utm_campaign
left join ya_view as ya
    on
	v.visit_date = ya.ya_campaign_date
	and v.utm_source = ya.utm_source
	and v.utm_medium = ya.utm_medium
	and v.utm_campaign = ya.utm_campaign
where
	v.rn = 1
group by
	coalesce(total_ya_spent,
	0) + coalesce(total_vk_spent,
	0),
	v.visit_date,
	v.utm_source,
	v.utm_medium,
	v.utm_campaign
order by
	sum(coalesce(v.amount, 0)) desc nulls last,
	v.visit_date asc,
	count(v.visitor_id) desc,
	v.utm_source asc,
	v.utm_medium asc,
	v.utm_campaign asc
limit 15;