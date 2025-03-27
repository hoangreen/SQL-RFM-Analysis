WITH CustSales AS (
    SELECT CustomerKey
        , COUNT(DISTINCT SalesOrderNumber) AS Frequency 
        , SUM(SalesAmount) AS Monetary 
        , MAX(OrderDate) AS MostRecentOrderDate 
        , DATEDIFF(DAY, MAX(OrderDate), (SELECT MAX(OrderDate) FROM dbo.FactInternetSales)) AS Recency 
    FROM dbo.FactInternetSales 
    GROUP BY CustomerKey
) 
, RFM_scoring AS (
    SELECT CustomerKey
        , NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency
        , NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency
        , NTILE(4) OVER (ORDER BY Monetary) AS rfm_monetary 
    FROM CustSales
)
, RFM_score AS (
    SELECT CustomerKey
        , CONCAT(rfm_recency, rfm_frequency, rfm_monetary) AS RFM_score
    FROM RFM_scoring
) 
, RFM_Segmentation AS ( 
    SELECT CustomerKey
        , RFM_score
        , CASE 
            WHEN RFM_score LIKE '1__' THEN 'Lost Customer' 
            WHEN RFM_score LIKE '[3,4][3,4][1,2]' THEN 'Promising' 
            WHEN RFM_score LIKE '[3,4][3,4][3,4]' THEN 'Loyal' 
            WHEN RFM_score LIKE '[3,4][1,2]_' THEN 'New customer' 
            WHEN RFM_score LIKE '[2,3,4][1,2][3,4]' THEN 'Big spenders' 
            WHEN RFM_score LIKE '2__' THEN 'Potential churn' 
         END AS CustomerSegmentation 
    FROM RFM_score
) 
SELECT 
    CustomerSegmentation
    , COUNT(CustomerKey) as NoCustomer 
FROM RFM_Segmentation
GROUP BY CustomerSegmentation;