WITH paid_sessions AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        s.content AS utm_content
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
        COUNT(DISTINCT p.visitor_id) AS visitors_count,
        DATE(p.visit_date) AS visit_date,
        p.utm_source,
        p.utm_medium,
        p.utm_campaign,
        COUNT(DISTINCT l.lead_id) AS leads_count,
        COUNT(
            DISTINCT l.lead_id) FILTER (
            WHERE l.closing_reason = 'Успешно реализовано'
            OR l.status_id = 142
        ) AS purchase_count,
        SUM(
            l.amount) FILTER (
            WHERE l.closing_reason = 'Успешно реализовано'
            OR l.status_id = 142
        ) AS revenue,
        ROW_NUMBER() OVER (
            PARTITION BY p.visitor_id
            ORDER BY p.visit_date DESC
        ) AS rn
    FROM leads AS l
    INNER JOIN paid_sessions AS p
        ON
            l.visitor_id = p.visitor_id
            AND l.created_at >= p.visit_date
    GROUP BY 2, 3, 4, 5
),

cost_ad AS (
    SELECT
        DATE(campaign_date) AS campaign_date,
        SUM(daily_spent) AS daily_spent,
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content
    FROM vk_ads
    GROUP BY
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content
    UNION ALL
    SELECT
        DATE(campaign_date) AS campaign_date,
        SUM(daily_spent) AS daily_spent,
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content
    FROM ya_ads
    GROUP BY
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content
)

SELECT
    lpc.visit_date,
    lpc.visitors_count,
    lpc.utm_source,
    lpc.utm_medium,
    lpc.utm_campaign,
    c.daily_spent,
    lpc.leads_count,
    lpc.purchase_count,
    lpc.revenue
FROM last_paid_click AS lpc
LEFT JOIN cost_ad AS c
    ON
        lpc.visit_date = c.campaign_date
        AND lpc.utm_source = c.utm_source
        AND lpc.utm_medium = c.utm_medium
        AND lpc.utm_campaign = c.utm_campaign
ORDER BY
    lpc.revenue DESC NULLS LAST,
    lpc.visit_date ASC,
    lpc.visitors_count DESC,
    lpc.utm_source ASC,
    lpc.utm_medium ASC,
    lpc.utm_campaign ASC
LIMIT 15;