with paid_sessions as (
    select
        s.visitor_id,
        s.visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign
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
        row_number() over (
            partition by p.visitor_id, p.visit_date
            order by p.visit_date desc
        ) as rn
    from leads as l
    inner join paid_sessions as p
        on
            l.visitor_id = p.visitor_id
            and l.created_at >= p.visit_date
)

select
    s.visitor_id,
    s.visit_date,
    lpc.utm_source,
    lpc.utm_medium,
    lpc.utm_campaign,
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
    lpc.utm_campaign asc;