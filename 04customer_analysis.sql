/*
-- Confirm customers columns
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'AdventureWorks_Customers'
ORDER BY ORDINAL_POSITION;

-- Check BirthDate range to confirm clean data
SELECT
    MIN(BirthDate) AS OldestCustomer,
    MAX(BirthDate) AS YoungestCustomer,
    COUNT(*) AS TotalCustomers,
    COUNT(BirthDate) AS HasBirthDate
FROM AdventureWorks_Customers;
*/

/*============================================
   ADVENTUREWORKS CUSTOMER ANALYSIS
   Analyst: Your Name
   Date: April 2026
   Database: AdventureWorks
   Purpose: Deep dive into customer behaviour,
   demographics, growth and segmentation
   Note: BirthDate outlier detected -- one
   customer born 1910-08-13 flagged as likely
   data entry error. Filtered in age analysis.
=============================================*/


/*--------------------------------------------
   SECTION 1: CUSTOMER GROWTH
   Goal: Understand how the customer base
   grew over time -- new customers per year
--------------------------------------------*/

-- First purchase date per customer
-- Identifies when each customer first bought
SELECT
    CustomerKey,
    MIN(OrderDate) AS FirstPurchaseDate,
    YEAR(MIN(OrderDate)) AS FirstPurchaseYear
INTO #CustomerFirstPurchase
FROM AllSales
GROUP BY CustomerKey;

-- New customers acquired per year
SELECT
    FirstPurchaseYear,
    COUNT(CustomerKey) AS NewCustomers
FROM #CustomerFirstPurchase
GROUP BY FirstPurchaseYear
ORDER BY FirstPurchaseYear;

-- Cumulative customer base over time
SELECT
    FirstPurchaseYear,
    COUNT(CustomerKey) AS NewCustomers,
    SUM(COUNT(CustomerKey)) OVER (
        ORDER BY FirstPurchaseYear
    ) AS CumulativeCustomers
FROM #CustomerFirstPurchase
GROUP BY FirstPurchaseYear
ORDER BY FirstPurchaseYear;

-- New customer revenue contribution per year
-- How much did first time buyers spend
SELECT
    YEAR(s.OrderDate) AS SalesYear,
    COUNT(DISTINCT s.CustomerKey) AS NewCustomerCount,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS NewCustomerRevenue
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
INNER JOIN #CustomerFirstPurchase AS f
    ON s.CustomerKey = f.CustomerKey
    AND YEAR(s.OrderDate) = f.FirstPurchaseYear
GROUP BY YEAR(s.OrderDate)
ORDER BY SalesYear;

/*--- SECTION 1 FINDINGS ---

New Customers Per Year:
- 2015: 2,630 new customers
- 2016: 7,929 new customers -- 201.5% increase
  Driven by Accessories and Clothing launch
  opening business to wider customer base
- 2017: 6,857 new customers in H1 only
  On pace for ~13,700 full year -- another
  major increase if H2 matches H1

Cumulative Customer Base:
- End 2015: 2,630 total buying customers
- End 2016: 10,559 total buying customers
- Mid 2017: 17,416 total buying customers
- 562% growth in buying customers over 2.5 years

Data Quality Finding:
- Customers table has 18,148 records
- Only 17,416 ever made a purchase
- 732 registered customers never bought anything
- These are in the Customers table but have
  no matching records in AllSales

Critical Finding -- New Customer Value Decline:
- 2015 avg new customer spend: $2,436
- 2016 avg new customer spend: $899 -- down 63%
- 2017 avg new customer spend: $571 -- down 36%
- Business acquiring more customers but each
  new customer is worth significantly less
- Growth in customer count masking decline
  in individual customer value
- Directly caused by product mix shift --
  new customers entering via accessories
  at $8-$100 price points vs bikes at $2,000+

Note: 2015 new customer revenue equals total
2015 revenue confirming every 2015 sale was
to a first time buyer -- no repeat customers
existed before 2015 in this dataset
--------------*/

/*--------------------------------------------
   SECTION 2: CUSTOMER RETENTION
   Goal: Find customers who bought in
   multiple years vs one time buyers
--------------------------------------------*/

-- How many years did each customer buy
SELECT
    YearsBuying,
    COUNT(CustomerKey) AS NumberOfCustomers,
    ROUND(
        CAST(COUNT(CustomerKey) AS float) /
        NULLIF((SELECT COUNT(DISTINCT CustomerKey) 
                FROM AllSales), 0) * 100
    , 2) AS PctOfAllCustomers
FROM (
    SELECT
        CustomerKey,
        COUNT(DISTINCT YEAR(OrderDate)) AS YearsBuying
    FROM AllSales
    GROUP BY CustomerKey
) CustomerYears
GROUP BY YearsBuying
ORDER BY YearsBuying;

-- Customers who bought in all three years
SELECT
    COUNT(DISTINCT CustomerKey) AS BoughtAllThreeYears
FROM (
    SELECT
        CustomerKey,
        COUNT(DISTINCT YEAR(OrderDate)) AS YearsBuying
    FROM AllSales
    GROUP BY CustomerKey
) CustomerYears
WHERE YearsBuying = 3;

-- Customers who bought in 2016 and returned in 2017
SELECT
    COUNT(DISTINCT s2017.CustomerKey) AS RetainedCustomers
FROM (
    SELECT DISTINCT CustomerKey
    FROM AllSales
    WHERE YEAR(OrderDate) = 2016
) s2016
INNER JOIN (
    SELECT DISTINCT CustomerKey
    FROM AllSales
    WHERE YEAR(OrderDate) = 2017
) s2017 ON s2016.CustomerKey = s2017.CustomerKey;

-- One time buyers -- only purchased in one year
SELECT
    COUNT(CustomerKey) AS OneTimeBuyers,
    ROUND(
        CAST(COUNT(CustomerKey) AS float) /
        NULLIF((SELECT COUNT(DISTINCT CustomerKey)
                FROM AllSales), 0) * 100
    , 2) AS PctOfAllCustomers
FROM (
    SELECT
        CustomerKey,
        COUNT(DISTINCT YEAR(OrderDate)) AS YearsBuying
    FROM AllSales
    GROUP BY CustomerKey
) CustomerYears
WHERE YearsBuying = 1;

/*--- SECTION 2 FINDINGS ---

Customer Loyalty Distribution:
- 73.87% of customers bought in 1 year only
- 24.42% bought in 2 years
- Only 1.71% bought across all 3 years (298 customers)
- Business has a significant retention problem --
  nearly 3 in 4 customers never return after
  their first purchase

2016 to 2017 Retention:
- 2,397 customers from 2016 returned in 2017
- Retention rate approximately 22.7% of 2016 base
- 77% of 2016 customers did not return in H1 2017
- Even accounting for partial 2017 year this is
  a low retention rate requiring attention

The 298 Loyal Customers:
- Only 298 customers bought in all three years
- Represent 1.71% of customer base but likely
  disproportionately high revenue contribution
- Almost certainly original 2015 bike buyers who
  continued purchasing after accessory launch
- These are the highest priority retention targets

Strategic Implication:
- Business is heavily dependent on new customer
  acquisition to drive revenue growth
- Low retention means growth stops the moment
  new customer acquisition slows down
- Improving retention from 22.7% to even 35%
  would significantly impact revenue without
  needing any new customers at all

Limitation: 2017 is H1 only -- some 2016 customers
may have returned in H2 2017 which would improve
the retention rate. True full year retention rate
cannot be calculated from available data.
--------------*/

/*--------------------------------------------
   SECTION 3: RFM SEGMENTATION
   Goal: Segment customers by Recency,
   Frequency and Monetary value
   Recency = days since last purchase
   Frequency = number of orders placed
   Monetary = total amount spent
--------------------------------------------*/

-- RFM base calculation per customer
SELECT
    s.CustomerKey,
    c.FirstName,
    c.LastName,
    DATEDIFF(day, MAX(s.OrderDate), '2017-06-30') AS Recency,
    COUNT(DISTINCT s.OrderNumber) AS Frequency,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS Monetary
INTO #RFM
FROM AllSales AS s
LEFT JOIN AdventureWorks_Customers AS c
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY s.CustomerKey, c.FirstName, c.LastName;

-- View RFM scores for top 20 customers
SELECT TOP 20 *
FROM #RFM
ORDER BY Monetary DESC;

-- Segment customers into groups based on RFM
SELECT
    CustomerKey,
    FirstName,
    LastName,
    Recency,
    Frequency,
    Monetary,
    CASE
        WHEN Recency <= 30 AND Frequency >= 5
            AND Monetary >= 5000  THEN 'Champions'
        WHEN Recency <= 90 AND Frequency >= 3
            AND Monetary >= 2000  THEN 'Loyal Customers'
        WHEN Recency <= 30 AND Frequency <= 2
            THEN 'Recent Buyers'
        WHEN Recency > 90 AND Frequency >= 3
            THEN 'At Risk'
        WHEN Recency > 180 AND Frequency = 1
            THEN 'Lost Customers'
        ELSE 'Occasional Buyers'
    END AS CustomerSegment
FROM #RFM
ORDER BY Monetary DESC;
-- Start of in RMF analysis *
-- Find high value At Risk customers
SELECT *
FROM #RFM
WHERE Recency > 90
AND Frequency >= 3
AND Monetary >= 5000
ORDER BY Monetary DESC;

-- Find high value Lost Customers worth re-engaging
SELECT *
FROM #RFM
WHERE Recency > 180
AND Frequency = 1
AND Monetary >= 3000
ORDER BY Monetary DESC;

-- Find Recent Buyers with high first purchase value
SELECT *
FROM #RFM
WHERE Recency <= 30
AND Frequency <= 2
AND Monetary >= 2000
ORDER BY Monetary DESC;
--End of RMF analysis

-- Count customers per segment
SELECT
    CASE
        WHEN Recency <= 30 AND Frequency >= 5
            AND Monetary >= 5000  THEN 'Champions'
        WHEN Recency <= 90 AND Frequency >= 3
            AND Monetary >= 2000  THEN 'Loyal Customers'
        WHEN Recency <= 30 AND Frequency <= 2
            THEN 'Recent Buyers'
        WHEN Recency > 90 AND Frequency >= 3
            THEN 'At Risk'
        WHEN Recency > 180 AND Frequency = 1
            THEN 'Lost Customers'
        ELSE 'Occasional Buyers'
    END AS CustomerSegment,
    COUNT(*) AS NumberOfCustomers,
    ROUND(AVG(Monetary), 2) AS AvgSpend,
    ROUND(SUM(Monetary), 2) AS TotalRevenue
FROM #RFM
GROUP BY
    CASE
        WHEN Recency <= 30 AND Frequency >= 5
            AND Monetary >= 5000  THEN 'Champions'
        WHEN Recency <= 90 AND Frequency >= 3
            AND Monetary >= 2000  THEN 'Loyal Customers'
        WHEN Recency <= 30 AND Frequency <= 2
            THEN 'Recent Buyers'
        WHEN Recency > 90 AND Frequency >= 3
            THEN 'At Risk'
        WHEN Recency > 180 AND Frequency = 1
            THEN 'Lost Customers'
        ELSE 'Occasional Buyers'
    END
ORDER BY TotalRevenue DESC;

/*--- SECTION 3 FINDINGS ---

RFM Framework Explanation:
- Recency: days since last purchase (lower = better)
- Frequency: number of distinct orders placed
- Monetary: total amount spent in dollars
- Reference date: 2017-06-30 (last date in dataset)
- All three dimensions combined to segment customers
  into six actionable groups

Segment Distribution:
- Occasional Buyers: 9,461 customers (54.3%)
  Avg spend $1,514 -- bought sporadically
- Lost Customers: 5,175 customers (29.7%)
  Avg spend $633 -- have not returned
- Loyal Customers: 408 customers (2.3%)
  Avg spend $6,158 -- consistent high spenders
- At Risk: 493 customers (2.8%)
  Avg spend $5,026 -- used to buy, gone quiet
- Recent Buyers: 1,873 customers (10.7%)
  Avg spend $1,206 -- bought recently
- Champions: only 6 customers (0.03%)
  Avg spend $10,470 -- best customers

Revenue by Segment:
- Occasional Buyers generate most revenue $14.3M
  but at only $1,514 avg per customer
- Loyal Customers only 408 people but spend
  $6,158 each -- 4x the occasional buyer rate
- At Risk segment critical: 493 customers
  spending $5,026 each -- $2.48M at risk
  if these customers stop buying entirely
- Champions: only 6 customers exist in entire
  18,148 customer base generating $62,822

RFM Thresholds Used:
- Champions: Recency <= 30, Frequency >= 5,
  Monetary >= 5000
- Loyal Customers: Recency <= 90, Frequency >= 3,
  Monetary >= 2000
- Recent Buyers: Recency <= 30, Frequency <= 2
- At Risk: Recency > 90, Frequency >= 3
- Lost Customers: Recency > 180, Frequency = 1
- Occasional Buyers: everything else

In-Depth Analysis -- At Risk Customers:
- Maurice Shan top priority: $12,407 total spend,
  6 orders, 105 days since last purchase
- Large cohort with 3-4 orders and $5,000-$10,000
  spend who have gone quiet
- Recency ranges from 91 to 283 days --
  some slipped away recently, others long ago
- Combined At Risk revenue: $2,477,704
- Most recoverable revenue segment in dataset

In-Depth Analysis -- Lost Customers:
- Road-150 Red Pattern discovered:
  Dozens of lost customers all spent exactly
  $3,578.27 -- the exact price of Road-150 Red
- All have Frequency 1 and Recency 700-900 days
- These are 2015 premium bike buyers who purchased
  once and never returned to the business
- Root cause: Accessories did not launch until
  July 2016 -- over a year after these customers
  bought their bike. No complementary products
  existed to bring them back at the time
- Re-engagement difficult given 700-900 day absence
- Represents a significant missed opportunity --
  premium bike buyers who could have been converted
  to accessories customers if launch had been earlier

In-Depth Analysis -- Recent Buyers High Value:
- Large group with Recency under 30 days,
  Frequency 2, spend between $2,000 and $6,000
- Caitlin Richardson: recency 6 days, 2 orders,
  $6,019 -- on verge of Loyal Customer status
- Multiple customers with Recency 0-1 days --
  purchased on or near final day of dataset
- Roberto Diaz: Recency 0, Frequency 2, $4,426 --
  bought twice with second purchase on last day
- Highest priority conversion targets --
  already showing repeat behaviour and high spend

Critical Finding -- Revenue Concentration:
- 84% of customers are Occasional or Lost buyers
- Only 16% of customers drive meaningful
  repeat revenue
- Business heavily dependent on constant new
  customer acquisition to sustain revenue
- If new customer acquisition slowed, revenue
  would drop significantly due to low retention

Critical Finding -- Champions Scarcity:
- Only 6 Champions in 18,148 customers
- For context a healthy business would expect
  Champions to represent 5-15% of customers
- Current rate is 0.03% -- extremely low
- Directly caused by low retention across
  all segments

Strategic Priority Order:
1. Retain At Risk segment -- $2.48M at stake
   Maurice Shan highest individual priority
2. Convert high spend Recent Buyers to Loyal --
   Caitlin Richardson and similar profiles
3. Investigate Road-150 Red churners --
   understand why premium buyers never returned
4. Accept 700-900 day lost customers unlikely
   to re-engage without significant incentive
5. Build Champions segment -- target is 5-15%
   of customer base not current 0.03%

Limitation: RFM thresholds set manually based
on dataset characteristics. Different thresholds
produce different segment sizes. Should be
reviewed with business context before acting
on strategic recommendations.

Data Quality Note: Temp table #RFM created in
Section 3 and used throughout. Must re-run
Section 3 if SSMS session is closed and reopened.
--------------*/

/*--------------------------------------------
   SECTION 4: GEOGRAPHIC CUSTOMER BREAKDOWN
   Goal: Understand where customers are
   and how valuable each region is
--------------------------------------------*/

-- Customers and revenue per territory
SELECT
    t.Region,
    t.Country,
    t.Continent,
    COUNT(DISTINCT s.CustomerKey) AS UniqueCustomers,
    COUNT(DISTINCT s.OrderNumber) AS TotalOrders,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue,
    ROUND(
        SUM(s.OrderQuantity * p.ProductPrice) /
        NULLIF(COUNT(DISTINCT s.CustomerKey), 0)
    , 2) AS RevenuePerCustomer
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
LEFT JOIN AdventureWorks_Territories AS t
    ON s.TerritoryKey = t.SalesTerritoryKey
GROUP BY t.Region, t.Country, t.Continent
ORDER BY TotalRevenue DESC;

-- Customers per continent
SELECT
    t.Continent,
    COUNT(DISTINCT s.CustomerKey) AS UniqueCustomers,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue,
    ROUND(
        SUM(s.OrderQuantity * p.ProductPrice) /
        NULLIF(COUNT(DISTINCT s.CustomerKey), 0)
    , 2) AS RevenuePerCustomer,
    ROUND(
        CAST(COUNT(DISTINCT s.CustomerKey) AS float) /
        NULLIF((SELECT COUNT(DISTINCT CustomerKey)
                FROM AllSales), 0) * 100
    , 2) AS PctOfAllCustomers
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
LEFT JOIN AdventureWorks_Territories AS t
    ON s.TerritoryKey = t.SalesTerritoryKey
GROUP BY t.Continent
ORDER BY TotalRevenue DESC;

/*--- SECTION 4 FINDINGS ---

Territory Performance:
- Australia: highest revenue per customer $2,131
  and 1.74 orders per customer -- most valuable
  and most loyal territory in entire dataset
- Southwest US: most unique customers (4,134)
  but only 1.21 orders per customer -- lowest
  repeat rate of any meaningful territory
- Canada: highest orders per customer at 2.02
  but lower spend per order -- accessory buyers
  rather than bike buyers

European Territories:
- All three European territories outperform
  North American territories on revenue per customer
- UK leads Europe at $1,593 per customer
- France and Germany consistent at $1,385-$1,507
- European customers 35% more valuable individually
  than North American customers

Dead Territory Confirmation:
- Southeast US: 10 customers, $392-$1,158 spend
- Northeast US: 8 customers
- Central US: 8 customers, $392 per customer
- These represent essentially test transactions
  not real commercial activity
- Combined 26 customers across three territories

Continent Analysis:
- North America: 50.15% of customers, $1,111 rev each
- Europe: 29.87% of customers, $1,497 rev each
- Pacific: 19.98% of customers, $2,131 rev each
- Inverse relationship between customer share
  and individual customer value
- Fewest customers (Pacific) = highest value
- Most customers (North America) = lowest value

Critical Finding -- Southwest US Opportunity:
- 4,134 customers with only 1.21 orders each
- If Southwest US matched Australia order rate
  of 1.74 orders per customer that would add
  approximately 2,200 additional orders
- At average revenue per order this represents
  a significant untapped revenue opportunity
  without acquiring a single new customer

Critical Finding -- Australian Customer Profile:
- Australia has fewer customers than Southwest US
  (3,480 vs 4,134) but generates 54% more revenue
  ($7.4M vs $4.8M)
- Australian customers are buying more expensive
  products and returning more often
- Understanding what drives Australian customer
  behaviour could inform strategy in other regions
--------------*/

/*--------------------------------------------
   SECTION 5: DEMOGRAPHIC ANALYSIS
   Goal: Understand customer demographics
   and how they relate to spending behaviour
--------------------------------------------*/

-- Revenue by age group
-- Note: BirthDate outlier 1910-08-13 excluded
SELECT
    CASE
        WHEN DATEDIFF(year, c.BirthDate, '2017-06-30')
            BETWEEN 25 AND 34 THEN '25-34'
        WHEN DATEDIFF(year, c.BirthDate, '2017-06-30')
            BETWEEN 35 AND 44 THEN '35-44'
        WHEN DATEDIFF(year, c.BirthDate, '2017-06-30')
            BETWEEN 45 AND 54 THEN '45-54'
        WHEN DATEDIFF(year, c.BirthDate, '2017-06-30')
            BETWEEN 55 AND 64 THEN '55-64'
        WHEN DATEDIFF(year, c.BirthDate, '2017-06-30')
            >= 65 THEN '65+'
        ELSE 'Under 25 or Unknown'
    END AS AgeGroup,
    COUNT(DISTINCT s.CustomerKey) AS NumberOfCustomers,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue,
    ROUND(
        SUM(s.OrderQuantity * p.ProductPrice) /
        NULLIF(COUNT(DISTINCT s.CustomerKey), 0)
    , 2) AS RevenuePerCustomer
FROM AllSales AS s
LEFT JOIN AdventureWorks_Customers AS c
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
WHERE c.BirthDate > '1920-01-01'
GROUP BY
    CASE
        WHEN DATEDIFF(year, c.BirthDate, '2017-06-30')
            BETWEEN 25 AND 34 THEN '25-34'
        WHEN DATEDIFF(year, c.BirthDate, '2017-06-30')
            BETWEEN 35 AND 44 THEN '35-44'
        WHEN DATEDIFF(year, c.BirthDate, '2017-06-30')
            BETWEEN 45 AND 54 THEN '45-54'
        WHEN DATEDIFF(year, c.BirthDate, '2017-06-30')
            BETWEEN 55 AND 64 THEN '55-64'
        WHEN DATEDIFF(year, c.BirthDate, '2017-06-30')
            >= 65 THEN '65+'
        ELSE 'Under 25 or Unknown'
    END
ORDER BY TotalRevenue DESC;

-- Revenue by marital status
SELECT
    CASE
        WHEN c.MaritalStatus = 'M' THEN 'Married'
        WHEN c.MaritalStatus = 'S' THEN 'Single'
        ELSE c.MaritalStatus
    END AS MaritalStatus,
    COUNT(DISTINCT s.CustomerKey) AS NumberOfCustomers,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue,
    ROUND(
        SUM(s.OrderQuantity * p.ProductPrice) /
        NULLIF(COUNT(DISTINCT s.CustomerKey), 0)
    , 2) AS RevenuePerCustomer
FROM AllSales AS s
LEFT JOIN AdventureWorks_Customers AS c
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY c.MaritalStatus
ORDER BY TotalRevenue DESC;

-- Revenue by education level
SELECT
    c.EducationLevel,
    COUNT(DISTINCT s.CustomerKey) AS NumberOfCustomers,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue,
    ROUND(
        SUM(s.OrderQuantity * p.ProductPrice) /
        NULLIF(COUNT(DISTINCT s.CustomerKey), 0)
    , 2) AS RevenuePerCustomer
FROM AllSales AS s
LEFT JOIN AdventureWorks_Customers AS c
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY c.EducationLevel
ORDER BY TotalRevenue DESC;

-- Revenue by homeowner status
SELECT
    CASE
        WHEN c.HomeOwner = 1 THEN 'Home Owner'
        WHEN c.HomeOwner = 0 THEN 'Renter'
    END AS HomeOwnerStatus,
    COUNT(DISTINCT s.CustomerKey) AS NumberOfCustomers,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue,
    ROUND(
        SUM(s.OrderQuantity * p.ProductPrice) /
        NULLIF(COUNT(DISTINCT s.CustomerKey), 0)
    , 2) AS RevenuePerCustomer
FROM AllSales AS s
LEFT JOIN AdventureWorks_Customers AS c
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY c.HomeOwner
ORDER BY TotalRevenue DESC;

-- Revenue by number of children
SELECT
    c.TotalChildren,
    COUNT(DISTINCT s.CustomerKey) AS NumberOfCustomers,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue,
    ROUND(
        SUM(s.OrderQuantity * p.ProductPrice) /
        NULLIF(COUNT(DISTINCT s.CustomerKey), 0)
    , 2) AS RevenuePerCustomer
FROM AllSales AS s
LEFT JOIN AdventureWorks_Customers AS c
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY c.TotalChildren
ORDER BY c.TotalChildren;

/*--- SECTION 5 FINDINGS ---

Age Group Analysis:
- 45-54 is core demographic: most customers (6,009)
  highest revenue ($9.9M) and highest spend per
  customer ($1,647)
- 55-64 second strongest at $1,570 per customer
- 35-44 and 65+ both below average at $1,132-$1,164
- No customers in 25-34 age group -- youngest
  customer born 1980, dataset covers 2015-2017
  meaning youngest buyers were 35-37 years old
- Two age groups (45-54 and 55-64) represent
  68.6% of total revenue combined

Marital Status:
- Near even split: 9,437 married vs 7,979 single
- Single customers spend 10% more per person
  ($1,506 vs $1,367)
- Counterintuitive finding -- single customers
  likely have more disposable income for
  discretionary premium purchases

Education Level:
- Clear positive correlation between education
  and revenue per customer
- Bachelors highest at $1,651 per customer
- Graduate Degree second at $1,556
- Partial High School lowest at $958
- Bachelors outperforms Graduate Degree --
  may reflect income vs debt burden difference
  or simply larger customer count in that group

Homeowner Status:
- Home owners 67.6% of customer base
- Home owners spend 9.8% more per customer
  ($1,473 vs $1,341)
- Home ownership correlates with financial
  stability and higher disposable income

Number of Children:
- Revenue per customer peaks at 1 child ($1,586)
- Steady decline as family size increases
- 5 children lowest at $1,134 per customer
- Large families have less disposable income
  for discretionary cycling purchases
- 0-2 children sweet spot for highest spend

Ideal Customer Profile:
- Age: 45-54 years old
- Marital status: Single or early stage married
- Education: Bachelors or Graduate degree
- Homeowner: Yes
- Children: 0-2
- Occupation: Professional (from descriptive analysis)
- Income: $60K-$90K middle to upper middle
- Location: Australia or European territory
- This profile represents the highest probability
  high value customer in the entire dataset

Data Quality Note:
- BirthDate outlier 1910-08-13 filtered from
  age analysis using WHERE BirthDate > 1920-01-01
- All other BirthDate values appear reasonable
--------------*/

/*--------------------------------------------
   SECTION 6: CUSTOMER LIFETIME VALUE
   Goal: Rank customers by total spend and
   identify high value customer profile
--------------------------------------------*/

-- Full customer lifetime value ranking
SELECT
    c.CustomerKey,
    c.FirstName,
    c.LastName,
    c.Occupation,
    c.AnnualIncome,
    c.EducationLevel,
    CASE
        WHEN c.HomeOwner = 1 THEN 'Yes'
        ELSE 'No'
    END AS HomeOwner,
    COUNT(DISTINCT s.OrderNumber) AS TotalOrders,
    SUM(s.OrderQuantity) AS TotalUnitsBought,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS LifetimeValue,
    RANK() OVER (
        ORDER BY SUM(s.OrderQuantity * p.ProductPrice) DESC
    ) AS ValueRank
FROM AllSales AS s
LEFT JOIN AdventureWorks_Customers AS c
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY
    c.CustomerKey, c.FirstName, c.LastName,
    c.Occupation, c.AnnualIncome,
    c.EducationLevel, c.HomeOwner
ORDER BY LifetimeValue DESC;

--Customer lifetime ranking analysis 
-- Top 20 customers by lifetime value with full profile
SELECT TOP 20
    c.CustomerKey,
    c.FirstName,
    c.LastName,
    c.Occupation,
    c.AnnualIncome,
    c.EducationLevel,
    CASE WHEN c.HomeOwner = 1 THEN 'Yes' ELSE 'No' END AS HomeOwner,
    COUNT(DISTINCT s.OrderNumber) AS TotalOrders,
    SUM(s.OrderQuantity) AS TotalUnitsBought,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS LifetimeValue,
    RANK() OVER (
        ORDER BY SUM(s.OrderQuantity * p.ProductPrice) DESC
    ) AS ValueRank
FROM AllSales AS s
LEFT JOIN AdventureWorks_Customers AS c
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY
    c.CustomerKey, c.FirstName, c.LastName,
    c.Occupation, c.AnnualIncome,
    c.EducationLevel, c.HomeOwner
ORDER BY LifetimeValue DESC;

-- Start Lifetime value distribution
-- How spread out are customer values
SELECT
    CASE
        WHEN LifetimeValue >= 10000 THEN '$10,000+'
        WHEN LifetimeValue >= 5000  THEN '$5,000-$9,999'
        WHEN LifetimeValue >= 2000  THEN '$2,000-$4,999'
        WHEN LifetimeValue >= 1000  THEN '$1,000-$1,999'
        WHEN LifetimeValue >= 500   THEN '$500-$999'
        ELSE 'Under $500'
    END AS ValueBand,
    COUNT(*) AS NumberOfCustomers,
    ROUND(SUM(LifetimeValue), 2) AS TotalRevenue,
    ROUND(
        CAST(COUNT(*) AS float) /
        NULLIF((SELECT COUNT(DISTINCT CustomerKey)
                FROM AllSales), 0) * 100
    , 2) AS PctOfCustomers,
    ROUND(
        SUM(LifetimeValue) /
        NULLIF((SELECT SUM(s.OrderQuantity * p.ProductPrice)
                FROM AllSales s
                LEFT JOIN AdventureWorks_Products p
                ON s.ProductKey = p.ProductKey), 0) * 100
    , 2) AS PctOfRevenue
FROM (
    SELECT
        s.CustomerKey,
        SUM(s.OrderQuantity * p.ProductPrice) AS LifetimeValue
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Products AS p
        ON s.ProductKey = p.ProductKey
    GROUP BY s.CustomerKey
) CustomerValues
GROUP BY
    CASE
        WHEN LifetimeValue >= 10000 THEN '$10,000+'
        WHEN LifetimeValue >= 5000  THEN '$5,000-$9,999'
        WHEN LifetimeValue >= 2000  THEN '$2,000-$4,999'
        WHEN LifetimeValue >= 1000  THEN '$1,000-$1,999'
        WHEN LifetimeValue >= 500   THEN '$500-$999'
        ELSE 'Under $500'
    END
ORDER BY MIN(LifetimeValue) DESC;

-- What percentage of revenue comes from top 10% of customers
SELECT
    TOP10Pct.CustomerCount AS Top10PctCustomers,
    ROUND(TOP10Pct.Top10Revenue, 2) AS Top10PctRevenue,
    ROUND(Total.TotalRevenue, 2) AS TotalRevenue,
    ROUND(TOP10Pct.Top10Revenue / Total.TotalRevenue * 100, 2) AS Top10PctOfRevenue
FROM (
    SELECT
        COUNT(*) AS CustomerCount,
        SUM(LifetimeValue) AS Top10Revenue
    FROM (
        SELECT TOP 10 PERCENT
            CustomerKey,
            SUM(s.OrderQuantity * p.ProductPrice) AS LifetimeValue
        FROM AllSales AS s
        LEFT JOIN AdventureWorks_Products AS p
            ON s.ProductKey = p.ProductKey
        GROUP BY CustomerKey
        ORDER BY LifetimeValue DESC
    ) Top10
) TOP10Pct
CROSS JOIN (
    SELECT SUM(s.OrderQuantity * p.ProductPrice) AS TotalRevenue
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Products AS p
        ON s.ProductKey = p.ProductKey
) Total;

--Top 20 customers 
SELECT TOP 20
    c.CustomerKey,
    c.FirstName,
    c.LastName,
    c.Occupation,
    c.AnnualIncome,
    c.EducationLevel,
    CASE WHEN c.HomeOwner = 1 THEN 'Yes' ELSE 'No' END AS HomeOwner,
    COUNT(DISTINCT s.OrderNumber) AS TotalOrders,
    SUM(s.OrderQuantity) AS TotalUnitsBought,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS LifetimeValue,
    RANK() OVER (
        ORDER BY SUM(s.OrderQuantity * p.ProductPrice) DESC
    ) AS ValueRank
FROM AllSales AS s
LEFT JOIN AdventureWorks_Customers AS c
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY
    c.CustomerKey, c.FirstName, c.LastName,
    c.Occupation, c.AnnualIncome,
    c.EducationLevel, c.HomeOwner
ORDER BY LifetimeValue DESC;

--End customer lifetime ranking analysis 

-- Average profile of top 100 customers
-- What do your best customers look like
SELECT
    AVG(DATEDIFF(year, c.BirthDate, '2017-06-30')) AS AvgAge,
    AVG(CAST(c.AnnualIncome AS float)) AS AvgIncome,
    AVG(CAST(c.TotalChildren AS float)) AS AvgChildren
FROM (
    SELECT TOP 100
        s.CustomerKey,
        SUM(s.OrderQuantity * p.ProductPrice) AS LifetimeValue
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Products AS p
        ON s.ProductKey = p.ProductKey
    GROUP BY s.CustomerKey
    ORDER BY LifetimeValue DESC
) TopCustomers
LEFT JOIN AdventureWorks_Customers AS c
    ON TopCustomers.CustomerKey = c.CustomerKey
WHERE c.BirthDate > '1920-01-01';

-- Top occupation among top 100 customers
SELECT TOP 5
    c.Occupation,
    COUNT(*) AS CustomerCount
FROM (
    SELECT TOP 100
        s.CustomerKey,
        SUM(s.OrderQuantity * p.ProductPrice) AS LifetimeValue
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Products AS p
        ON s.ProductKey = p.ProductKey
    GROUP BY s.CustomerKey
    ORDER BY LifetimeValue DESC
) TopCustomers
LEFT JOIN AdventureWorks_Customers AS c
    ON TopCustomers.CustomerKey = c.CustomerKey
GROUP BY c.Occupation
ORDER BY CustomerCount DESC;

/*--- SECTION 6: FULL LIFETIME VALUE FINDINGS ---

Top 20 Customer Profiles:
Rank  Name              Occupation    Income    Education        HomeOwner  Orders  LTV
1     Maurice Shan      Professional  $80,000   High School      No         6       $12,407
2     Janet Munoz       Management    $90,000   High School      No         6       $12,015
3     Lisa Cai          Professional  $100,000  Partial College  Yes        7       $11,330
4     Lacey Zheng       Professional  $70,000   High School      Yes        7       $11,085
5     Jordan Turner     Management    $100,000  Bachelors        Yes        7       $11,022
6     Larry Munoz       Professional  $110,000  Partial College  Yes        7       $10,852
7     Kate Anand        Professional  $110,000  Partial College  Yes        4       $10,436
8     Larry Vazquez     Management    $80,000   High School      Yes        4       $10,394
9     Ariana Gray       Professional  $90,000   High School      Yes        6       $10,391
10    Clarence Gao      Professional  $70,000   High School      Yes        4       $10,331

Observations From Top 20:
- Professional: 13 of top 20 customers (65%)
- Management: 7 of top 20 customers (35%)
- No other occupation appears in top 20
- Income range: $70,000 to $130,000
- Most common income: $80,000 (5 customers)
- Education: mostly High School and Partial College
  contrary to population level finding that
  Bachelors correlates with highest spend
- Home Owner: 15 of 20 are home owners (75%)
- Orders range: 4 to 7 per customer
- No top 20 customer has fewer than 4 orders
- Lowest lifetime value in top 20: $9,706

Education Surprise in Top 20:
- Population level finding: Bachelors highest spend
- Top 20 finding: High School and Partial College
  dominate the very best customers
- Only 4 of top 20 have Bachelors degree
- Clarence Anand rank 16 has highest income
  ($130,000) but not highest lifetime value
- Suggests at elite spending level education
  is not the primary driver -- occupation
  and repeat purchase behaviour matter more

Income Observations in Top 20:
- No top 20 customer earns under $70,000
- No top 20 customer earns over $130,000
- Sweet spot is $80,000-$110,000
- Clarence Anand at $130,000 ranks only 16th
  despite highest income in top 20
- Confirms income alone does not predict
  top customer status -- frequency matters

Lifetime Value Distribution:
ValueBand       Customers    PctCustomers    Revenue         PctRevenue
$10,000+        16           0.09%           $171,709        0.69%
$5,000-$9,999   1,173        6.74%           $7,337,979      29.45%
$2,000-$4,999   4,182        24.01%          $13,072,381     52.47%
$1,000-$1,999   1,819        10.44%          $2,554,912      10.25%
$500-$999       1,639        9.41%           $1,058,857      4.25%
Under $500      8,587        49.31%          $718,746        2.88%

Key Distribution Findings:
- $2,000-$4,999 band is the revenue engine:
  24% of customers generate 52.47% of revenue
  This is the single most important customer band
- Under $500 band: 49.31% of all customers
  generate only 2.88% of revenue
  Nearly half the customer base contributes
  almost nothing to total revenue
- $10,000+ elite: only 16 customers exist
  generating just 0.69% of revenue despite
  being the highest individual spenders
  Small group, individually impressive but
  not revenue critical at current size
- 80/20 Analysis:
  $2,000+ spenders = 30.84% of customers
  generate 82.61% of revenue
  Business follows modified 80/20 rule --
  top 31% generates 83% of revenue

Top 10% Revenue Concentration:
- Top 10% of customers: 1,742 people
- Their revenue: $10,055,018
- Share of total revenue: 40.36%
- Bottom 90% of customers: 15,674 people
- Their revenue: $14,859,568 -- 59.64%
- Less extreme than typical retail which
  often sees 50-60% in top 10%
- Suggests middle tier customers are
  reasonably valuable in this business

Critical Finding -- The $2,000-$4,999 Band:
- This band is the true foundation of the business
- 4,182 customers spending $2,000-$4,999 each
- These are likely one or two bike purchases
  plus some accessories
- Losing this band would destroy the business
- Retaining and upgrading these customers
  to $5,000+ should be the primary strategic focus
- Converting even 10% of this band to $5,000+
  would add approximately $1.2M in revenue

Critical Finding -- Under $500 Dead Weight:
- 8,587 customers spending under $500 total
- Generating only $718,746 combined
- Average spend: $83.69 per customer
- These are almost entirely accessory only buyers
  who made one small purchase and never returned
- Cost of acquiring these customers likely
  exceeds their lifetime revenue contribution
- Business should not prioritise acquiring
  more customers like this

Revised Ideal Customer Profile:
After combining all Section 6 findings with
Sections 3 through 5 the complete profile is:

Occupation: Professional or Management (100% of top 20)
Income: $80,000-$110,000 sweet spot
Education: less predictive than occupation
Home Owner: Yes (75% of top 20)
Orders: minimum 4 orders to reach top tier
Age: late 50s average
Location: Australia or Europe
RFM: Low recency, high frequency, high monetary

One customer matching this profile is worth
approximately 148x a typical Under $500 customer
($10,000 lifetime value vs $83 average)
--------------*/

/*--- CUSTOMER ANALYSIS COMPLETE SUMMARY ---

Six Key Findings Across All Sections:

1. New customer value declining:
   $2,436 per new customer in 2015 vs
   $571 in 2017 -- product mix shift impact

2. Retention crisis:
   73.87% of customers bought once only
   Only 298 customers bought all three years

3. RFM reveals $2.48M at risk:
   493 At Risk customers with avg $5,026 spend
   Maurice Shan #1 customer is At Risk

4. Geographic value gap:
   Australia $2,131 per customer vs
   North America $1,111 per customer

5. Revenue concentration:
   Top 31% of customers generate 83% of revenue
   49% of customers generate under 3% of revenue

6. Ideal customer profile defined:
   Late 50s Professional or Management
   $80K-$110K income, home