with attr as (
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
,
aggr_data as (
select
	utm_source,
	utm_medium,
	utm_campaign,
	date(visit_date) as visit_date,
	count(visitor_id) as visitors_count,
	count(case when created_at is not null then visitor_id end) as leads_count,
	count(case when status_id = 142 then visitor_id end) as purchases_count,
	sum(case when status_id = 142 then amount end) as revenue
from
	attr
where
	count_m = 1
group by
	utm_source,
	utm_medium,
	utm_campaign,
	date(visit_date)
),

marketing_data as (
select
	date(campaign_date) as visit_date,
	utm_source,
	utm_medium,
	utm_campaign,
	sum(daily_spent) as total_cost
from
	ya_ads
group by
	date(campaign_date),
	utm_source,
	utm_medium,
	utm_campaign
union all
select
	date(campaign_date) as visit_date,
	utm_source,
	utm_medium,
	utm_campaign,
	sum(daily_spent) as total_cost
from
	vk_ads
group by
	date(campaign_date),
	utm_source,
	utm_medium,
	utm_campaign
)

select
	ad.visit_date,
	ad.utm_source,
	ad.utm_medium,
	ad.utm_campaign,
	md.total_cost,
	ad.visitors_count,
	ad.leads_count,
	ad.purchases_count,
	ad.revenue
from
	aggr_data as ad
left join marketing_data as md
    on
	ad.visit_date = md.visit_date
	and lower(ad.utm_source) = md.utm_source
	and lower(ad.utm_medium) = md.utm_medium
	and lower(ad.utm_campaign) = md.utm_campaign
order by
	purchases_count desc
limit 15;