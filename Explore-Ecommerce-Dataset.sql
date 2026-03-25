-- Query 01: calculate total visit, pageview, transaction for Jan, Feb and March 2017 (order by month)

SELECT
  SUBSTR(date, 1, 6) AS month,
  SUM(totals.visits) AS visits,
  SUM(totals.pageviews) AS pageviews,
  SUM(totals.transactions) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE SUBSTR(date, 1, 6) BETWEEN '201701' AND '201703'
GROUP BY month
ORDER BY month;

-- Query 02: Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)
      
SELECT
  trafficSource.source AS source,
  SUM(totals.visits) AS total_visits,
  SUM(totals.bounces) AS total_no_of_bounces,
  ROUND(SUM(totals.bounces) / SUM(totals.visits) * 100, 3) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE SUBSTR(date, 1, 6) = '201707'
GROUP BY source
ORDER BY total_visits DESC;

-- Query 03: Revenue by traffic source by week, by month in June 2017

      -- MONTH revenue (June 2017)
          SELECT
            'Month' AS time_type,
            SUBSTR(date, 1, 6) AS time,
            trafficSource.source AS source,
            SUM(product.productRevenue) / 1000000 AS revenue
          FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
          UNNEST(hits) AS hits,
          UNNEST(hits.product) AS product
          WHERE SUBSTR(date, 1, 6) = '201706'
            AND product.productRevenue IS NOT NULL
          GROUP BY time, source

          UNION ALL

          -- WEEK revenue (June 2017)
          SELECT
            'Week' AS time_type,
            FORMAT_DATE('%Y%V', PARSE_DATE('%Y%m%d', date)) AS time,
            trafficSource.source AS source,
            SUM(product.productRevenue) / 1000000 AS revenue
          FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
          UNNEST(hits) AS hits,
          UNNEST(hits.product) AS product
          WHERE SUBSTR(date, 1, 6) = '201706'
            AND product.productRevenue IS NOT NULL
          GROUP BY time, source
          ORDER BY time_type, time, revenue DESC;

--Query 04: Conversion rate by traffic source in 2017. (order by conversion_rate desc)


          SELECT
              trafficSource.source as source
              ,SUM(totals.visits) AS visits
              ,SUM(totals.transactions) as transactions
              ,CONCAT(CAST(ROUND(100.0* SUM(totals.transactions)/SUM(totals.visits),2) AS STRING),'%') as conversion_rate
          FROM 
              `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
          WHERE SUBSTR(date,1,4) ='2017'
          GROUP BY 1
          HAVING SUM(totals.transactions) >=50
          ORDER BY 4 DESC;

-- Query 05: Average number of pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017.

WITH T_JUNE AS (
   SELECT SUBSTR(date,1,6) as month
          ,SUM(totals.pageviews)/COUNT(DISTINCT fullVisitorId ) as avg_pageviews_purchase
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
    ,UNNEST(hits) as  hits
    ,UNNEST(hits.product) as product
    WHERE SUBSTR(date, 1, 6) BETWEEN '201706' AND '201707'
    AND   totals.transactions >=1 AND  productRevenue is not null
    GROUP BY 1
    ),
      T_JULY AS (
    SELECT SUBSTR(date,1,6) as month
          ,SUM(totals.pageviews)/COUNT(DISTINCT fullVisitorId ) as avg_pageviews_non_purchase
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
    ,UNNEST(hits) as  hits
    ,UNNEST(hits.product) as product
    WHERE SUBSTR(date, 1, 6) BETWEEN '201706' AND '201707'
    AND   totals.transactions is null AND  productRevenue is null
    GROUP BY 1 
    )
SELECT 
  T_JUNE.month
  ,T_JUNE.avg_pageviews_purchase
  ,T_JULY.avg_pageviews_non_purchase
FROM T_JUNE
FULL JOIN T_JULY
USING (month);

--- Query 06: Average number of transactions per user that made a purchase in July 2017
SELECT 
    SUBSTR(date,1,6) as month
    ,SUM(totals.transactions)/count(DISTINCT fullVisitorId) as Avg_total_transactions_per_user
FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
,UNNEST(hits) as  hits
,UNNEST(hits.product) as product
WHERE totals.transactions >=1 AND product.productRevenue is not null
AND  SUBSTR(date,1,6) ='201707'
GROUP BY 1;

--- Query 07: Revenue contribution by device (desktop,mobile...) (order by ratio desc)


SELECT
  device.deviceCategory AS device,
  SUM(product.productRevenue) / 1000000 AS revenue_by_device,
  SUM(SUM(product.productRevenue) / 1000000) OVER() AS total_revenue,
  ROUND(100* (SUM(product.productRevenue) / 1000000)
    / SUM(SUM(product.productRevenue) / 1000000) OVER(),2) AS ratio
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
     UNNEST(hits) AS hits,
     UNNEST(hits.product) AS product
WHERE totals.transactions IS NOT NULL
  AND product.productRevenue IS NOT NULL
GROUP BY device
ORDER BY ratio DESC;

--- Query 08: Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017. Output should show product name and the quantity was ordered.
SELECT 
    product.v2ProductName AS other_purchased_products
    ,SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
,UNNEST(hits) as  hits
,UNNEST(hits.product) as product
WHERE totals.transactions >=1 AND product.productRevenue is not null 
AND  product.v2ProductName != "YouTube Men's Vintage Henley"
AND fullVisitorId IN (
    SELECT 
        DISTINCT(fullVisitorId)
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    ,UNNEST(hits) as  hits
    ,UNNEST(hits.product) as product
     WHERE totals.transactions >=1 AND product.productRevenue is not null 
      AND product.v2ProductName = "YouTube Men's Vintage Henley"
) 
GROUP BY 1
ORDER BY 2 DESC;

--- Query 9: Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. For example, 100% product view then 40% add_to_cart and 10% purchase.
with t as (
SELECT
   SUBSTR(date,1,6) as month
  ,SUM(CASE WHEN hits.eCommerceAction.action_type ='2' THEN 1  END) AS num_product_view
  ,SUM(CASE WHEN hits.eCommerceAction.action_type ='3' THEN 1  END) AS num_addtocart
  ,SUM(CASE WHEN hits.eCommerceAction.action_type ='6' AND product.productRevenue IS NOT NULL THEN 1 END) AS num_purchase
FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
,UNNEST(hits) as  hits
,UNNEST(hits.product) as product
WHERE SUBSTR (date, 1,6 ) between '201701' and '201703'
GROUP BY 1) 
SELECT 
     month, num_product_view,num_addtocart,num_purchase
    ,ROUND(100.0* num_addtocart/num_product_view,2) AS add_to_cart_rate
    ,ROUND(100.0* num_purchase/num_product_view,2) AS purchase_rate
FROM t
ORDER BY 1;

---Query 10: Calculate revenue by week from May to July 2017 and culmulative revenue.
WITH week_revenue AS (
    SELECT 
        FORMAT_DATE('%Y-%W', PARSE_DATE('%Y%m%d', date)) AS week,
        ROUND(SUM(product.productRevenue) / 1000000, 2) AS weekly_revenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits, UNNEST(hits.product) AS product
    WHERE _table_suffix BETWEEN '0501' AND '0731' AND product.productRevenue IS NOT NULL
    GROUP BY week
    ORDER BY week
)
SELECT 
    week, weekly_revenue,
    ROUND(SUM(weekly_revenue) OVER(ORDER BY week), 2) AS cumulative_revenue
FROM week_revenue;




  


