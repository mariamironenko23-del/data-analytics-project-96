with paid_sessions as (
    select
        s.visitor_id,
        s.visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        s.content as utm_content
    from sessions as s
    where s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

last_paid_click as (
    select
        l.lead_id,
        p.visitor_id,
        p.visit_date,
        p.utm_source,
        p.utm_medium,
        p.utm_campaign,
        p.utm_content,
        row_number() over (
            partition by p.visitor_id, p.visit_date
            order by p.visit_date desc
        ) as rn
    from leads as l
    inner join paid_sessions as p
        on
            l.visitor_id = p.visitor_id
            and l.created_at >= p.visit_date
),

case1 as (
    select
        s.visitor_id,
        s.visit_date,
        lpc.utm_source,
        lpc.utm_medium,
        lpc.utm_campaign,
        lpc.utm_content,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id
    from sessions as s
    left join leads as l
        on
            s.visitor_id = l.visitor_id
            and s.visit_date <= l.created_at
    left join last_paid_click as lpc
        on
            s.visitor_id = lpc.visitor_id
            and lpc.rn = 1
            and s.visit_date >= lpc.visit_date
    order by
        l.amount desc nulls last,
        s.visit_date asc,
        lpc.utm_source asc,
        lpc.utm_medium asc,
        lpc.utm_campaign asc,
        lpc.utm_content asc
)

select
    c.visit_date,
    c.utm_source,
    c.utm_medium,
    c.utm_campaign,
    count(distinct c.visitor_id) as visitors_count,
    coalesce(sum(vk.daily_spent), 0)
    + coalesce(sum(ya.daily_spent), 0) as total_cost,
    count(distinct c.lead_id) as leads_count,
    count(
        distinct c.lead_id) filter (
        where c.closing_reason = 'Успешно реализовано'
        or c.status_id = 142
    ) as purchase_count,
    sum(
        c.amount) filter (
        where c.closing_reason = 'Успешно реализовано'
        or c.status_id = 142
    ) as revenue
from case1 as c
left join vk_ads as vk
    on
        c.visit_date = vk.campaign_date
        and c.utm_source = vk.utm_source
        and c.utm_medium = vk.utm_medium
        and c.utm_campaign = vk.utm_campaign
        and c.utm_content = vk.utm_content
left join ya_ads as ya
    on
        c.visit_date = ya.campaign_date
        and c.utm_source = ya.utm_source
        and c.utm_medium = ya.utm_medium
        and c.utm_campaign = ya.utm_campaign
        and c.utm_content = ya.utm_content
group by
    c.visit_date, c.utm_source,
    c.utm_medium,
    c.utm_campaign
order by
    revenue desc nulls last,
    c.visit_date asc,
    visitors_count desc,
    c.utm_source asc,
    c.utm_medium asc,
    c.utm_campaign asc;