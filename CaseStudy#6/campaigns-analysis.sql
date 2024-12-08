-- Generate a table that has 1 single row for every unique visit_id record and has the following columns:
-- user_id
-- visit_id
-- visit_start_time: the earliest event_time for each visit
-- page_views: count of page views for each visit
-- cart_adds: count of product cart add events for each visit
-- purchase: 1/0 flag if a purchase event exists for each visit
-- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
-- impression: count of ad impressions for each visit
-- click: count of ad clicks for each visit
-- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)
-- Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.

CREATE TABLE campaign_analysis
(
    user_id          int,
    visit_id         varchar,
    visit_start_time timestamp,
    page_views       int,
    cart_adds        int,
    purchase         int,
    impressions      int,
    click            int,
    campaign         varchar,
    cart_products    varchar
);
WITH cte AS (SELECT DISTINCT visit_id,
                             user_id,
                             MIN(event_time)                                               AS visit_start_time,
                             COUNT(e.page_id)                                              AS page_views,
                             SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END)   AS cart_adds,
                             SUM(CASE WHEN event_name = 'Purchase' THEN 1 ELSE 0 END)      AS purchase,
                             SUM(CASE WHEN event_name = 'Ad Impression' THEN 1 ELSE 0 END) AS impressions,
                             SUM(CASE WHEN event_name = 'Ad Click' THEN 1 ELSE 0 END)      AS click,
                             CASE
                                 WHEN MIN(event_time) > '2020-01-01 00:00:00' AND
                                      MIN(event_time) < '2020-01-14 00:00:00'
                                     THEN 'BOGOF - Fishing For Compliments'
                                 WHEN MIN(event_time) > '2020-01-15 00:00:00' AND
                                      MIN(event_time) < '2020-01-28 00:00:00'
                                     THEN '25% Off - Living The Lux Life'
                                 WHEN MIN(event_time) > '2020-02-01 00:00:00' AND
                                      MIN(event_time) < '2020-03-31 00:00:00'
                                     THEN 'Half Off - Treat Your Shellf(ish)'
                                 END                                                       AS campaign,
                             STRING_AGG(CASE
                                            WHEN product_id IS NOT NULL AND event_name = 'Add to Cart'
                                                THEN page_name
                                            END, ', ')                                     AS cart_products
             FROM events e
                      JOIN event_identifier ei
                           ON e.event_type = ei.event_type
                      JOIN users u
                           ON u.cookie_id = e.cookie_id
                      JOIN page_hierarchy ph ON e.page_id = ph.page_id
             GROUP BY visit_id, user_id)
INSERT INTO campaign_analysis
(user_id, visit_id, visit_start_time, page_views, cart_adds, purchase, impressions, click, Campaign, cart_products)
SELECT user_id,
       visit_id,
       visit_start_time,
       page_views,
       cart_adds,
       purchase,
       impressions,
       click,
       Campaign,
       cart_products
FROM cte;