WITH paid_sessions AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign
    FROM sessions AS s
    WHERE s.medium IN (
        'cpc',
        'cpm',
        'cpa',
        'youtube',
        'cpp',
        'tg',
        'social'
    )
),

last_paid_click AS (
    SELECT
        p.visitor_id,
        p.visit_date,
        p.utm_source,
        p.utm_medium,
        p.utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        ROW_NUMBER() OVER (
            PARTITION BY p.visitor_id
            ORDER BY p.visit_date DESC
        ) AS rn
    FROM leads AS l
    INNER JOIN paid_sessions AS p
        ON
            l.visitor_id = p.visitor_id
            AND l.created_at >= p.visit_date
)

SELECT
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
FROM last_paid_click
WHERE rn = 1
ORDER BY
    amount DESC NULLS LAST,
    visit_date ASC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC

LIMIT 10;
