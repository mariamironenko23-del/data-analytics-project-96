WITH paid_sessions AS (
    SELECT
        p.visitor_id,
        p.visit_date,
        p.source AS utm_source,
        p.medium AS utm_medium,
        p.campaign AS utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        ROW_NUMBER() OVER (
            PARTITION BY p.visitor_id
            ORDER BY p.visit_date DESC
        ) AS rn
    FROM sessions AS p
    LEFT JOIN leads AS l
        ON p.visitor_id = l.visitor_id AND p.visit_date <= l.created_at
    WHERE p.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

last_paid_click AS (
    SELECT
        p.utm_source,
        p.utm_medium,
        p.utm_campaign,
        DATE(p.visit_date) AS visit_date,
        COUNT(p.visitor_id) AS visitors_count,
        COUNT(p.lead_id) AS leads_count,
        COUNT(p.lead_id)
        FILTER (
            WHERE p.closing_reason = 'Успешно реализовано' OR p.status_id = 142
        ) AS purchases_count,
        SUM(
            CASE
                WHEN
                    p.closing_reason = 'Успешно реализовано'
                    OR p.status_id = 142
                    THEN p.amount
                ELSE 0
            END
        ) AS revenue
    FROM paid_sessions AS p
    WHERE p.rn = 1
    GROUP BY DATE(p.visit_date), p.utm_source, p.utm_medium, p.utm_campaign
),

cost_ad AS (
    SELECT
        DATE(campaign_date) AS campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM vk_ads
    GROUP BY
        DATE(campaign_date),
        utm_source,
        utm_medium,
        utm_campaign
    UNION ALL
    SELECT
        DATE(campaign_date) AS campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM ya_ads
    GROUP BY DATE(campaign_date), utm_source, utm_medium, utm_campaign
)

SELECT
    lpc.visit_date,
    lpc.visitors_count,
    lpc.utm_source,
    lpc.utm_medium,
    lpc.utm_campaign,
    c.total_cost,
    lpc.leads_count,
    lpc.purchases_count,
    lpc.revenue
FROM last_paid_click AS lpc
LEFT JOIN cost_ad AS c
    ON
        lpc.visit_date = c.campaign_date
        AND lpc.utm_source = c.utm_source
        AND lpc.utm_medium = c.utm_medium
        AND lpc.utm_campaign = c.utm_campaign
ORDER BY
    lpc.revenue
    DESC NULLS LAST, lpc.visit_date ASC,
    lpc.visitors_count DESC,
    lpc.utm_source ASC,
    lpc.utm_medium ASC,
    lpc.utm_campaign ASC

