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
),

lpc_view as (
select
	*
from
	lpc
order by
	amount desc nulls last,
	visit_date asc,
	"source" asc,
	medium asc,
	campaign asc
),
lpc_revenue as (
select
	date_trunc('day',
	visit_date)::date as visit_date,
	"source",
	medium,
	campaign,
	count(visitor_id) as visitors_count,
	count(lead_id) as leads_count,
	count(
            case
                when
                    closing_reason = 'Успешная продажа' or status_id = 142
                    then lead_id
            end
        ) as purch_count,
	sum(
            case
                when
                    closing_reason = 'Успешная продажа' or status_id = 142
                    then amount
            end
        ) as revenue
from
	lpc_view
group by
	date_trunc('day',
	visit_date)::date,
	"source",
	medium,
	campaign
order by
	revenue desc nulls last,
	visit_date asc,
	visitors_count desc,
	"source" asc,
	medium asc,
	campaign asc
),
vk_view as (
select
	date_trunc('day',
	campaign_date)::date as campaign_date,
	utm_source,
	utm_medium,
	utm_campaign,
	sum(daily_spent) as daily_spent
from
	vk_ads
where
	utm_medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
group by
	date_trunc('day',
	campaign_date)::date,
	utm_source,
	utm_medium,
	utm_campaign
),

ya_view as (
select
	date_trunc('day',
	campaign_date)::date as campaign_date,
	utm_source,
	utm_medium,
	utm_campaign,
	sum(daily_spent) as daily_spent
from
	ya_ads
where
	utm_medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
group by
	date_trunc('day',
	campaign_date)::date,
	utm_source,
	utm_medium,
	utm_campaign
)

select
	lpcr.visit_date,
	lpcr."source",
	lpcr.medium,
	lpcr.campaign,
	lpcr.visitors_count,
	lpcr.leads_count,
	lpcr.purch_count,
	lpcr.revenue,
	coalesce(vk_view.daily_spent,
	ya_view.daily_spent,
	0) as total_cost
from
	lpc_revenue as lpcr
left join vk_view
    on
	lpcr.visit_date = vk_view.campaign_date
	and lpcr."source" = vk_view.utm_source
	and lpcr.medium = vk_view.utm_medium
	and lpcr.campaign = vk_view.utm_campaign
left join ya_view
    on
	lpcr.visit_date = ya_view.campaign_date
	and lpcr."source" = ya_view.utm_source
	and lpcr.medium = ya_view.utm_medium
	and lpcr.campaign = ya_view.utm_campaign
limit 15;