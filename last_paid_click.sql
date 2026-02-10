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
        l.lead_id,
        p.visitor_id,
        p.visit_date,
        p.utm_source,
        p.utm_medium,
        p.utm_campaign,
        ROW_NUMBER() OVER (
            PARTITION BY l.lead_id
            ORDER BY p.visit_date DESC
        ) AS rn
    FROM leads AS l
    INNER JOIN paid_sessions AS p
        ON
            l.visitor_id = p.visitor_id
            AND l.created_at >= p.visit_date
)

SELECT
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
FROM sessions AS s
LEFT JOIN leads AS l
    ON
        s.visitor_id = l.visitor_id
        AND s.visit_date <= l.created_at
LEFT JOIN last_paid_click AS lpc
    ON
        l.lead_id = lpc.lead_id
        AND lpc.rn = 1
ORDER BY
    l.amount DESC NULLS LAST,
    s.visit_date ASC,
    lpc.utm_source ASC,
    lpc.utm_medium ASC,
    lpc.utm_campaign ASC;