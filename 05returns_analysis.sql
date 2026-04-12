/*
-- Confirm Returns columns
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'AdventureWorks_Returns'
ORDER BY ORDINAL_POSITION;

-- Preview Returns table
SELECT TOP 10 *
FROM AdventureWorks_Returns;

-- Check date range of returns
SELECT
    MIN(ReturnDate) AS EarliestReturn,
    MAX(ReturnDate) AS LatestReturn,
    COUNT(*) AS TotalReturnTransactions,
    SUM(ReturnQuantity) AS TotalUnitsReturned
FROM AdventureWorks_Returns;
*/

/*============================================
   ADVENTUREWORKS RETURNS ANALYSIS
   Analyst: Your Name
   Date: April 2026
   Database: AdventureWorks
   Purpose: Diagnostic analysis of product
   returns to identify problem products,
   categories, territories and trends
   Note: Returns table has no CustomerKey --
   cannot link returns to specific customers
   Analysis limited to product, territory
   and time dimensions
=============================================*/


/*--------------------------------------------
   SECTION 1: OVERALL RETURNS SUMMARY
   Goal: Understand the scale of returns
   and establish baseline metrics
--------------------------------------------*/

-- Total returns overview
SELECT
    COUNT(*) AS TotalReturnTransactions,
    SUM(ReturnQuantity) AS TotalUnitsReturned,
    COUNT(DISTINCT ProductKey) AS UniqueProductsReturned,
    COUNT(DISTINCT TerritoryKey) AS TerritoriesWithReturns,
    ROUND(AVG(CAST(ReturnQuantity AS float)), 2) AS AvgUnitsPerReturn,
    MIN(ReturnDate) AS EarliestReturn,
    MAX(ReturnDate) AS LatestReturn
FROM AdventureWorks_Returns;

-- Total units sold for context
SELECT
    SUM(OrderQuantity) AS TotalUnitsSold,
    COUNT(DISTINCT ProductKey) AS UniqueProductsSold
FROM AllSales;

-- Overall return rate
SELECT
    r.TotalReturned,
    s.TotalSold,
    ROUND(
        CAST(r.TotalReturned AS float) /
        NULLIF(s.TotalSold, 0) * 100
    , 2) AS OverallReturnRatePct
FROM (
    SELECT SUM(ReturnQuantity) AS TotalReturned
    FROM AdventureWorks_Returns
) r
CROSS JOIN (
    SELECT SUM(OrderQuantity) AS TotalSold
    FROM AllSales
) s;

-- Returns that have no matching product in Products table
-- Data quality check
SELECT COUNT(*) AS UnmatchedReturns
FROM AdventureWorks_Returns AS r
LEFT JOIN AdventureWorks_Products AS p
    ON r.ProductKey = p.ProductKey
WHERE p.ProductKey IS NULL;

/*--- SECTION 1 FINDINGS ---

Returns Overview:
- 1,809 return transactions across 2.5 years
- 1,828 total units returned
- Average 1.01 units per return transaction --
  almost every return is a single unit
  consistent with single unit purchase pattern
- 8 of 10 territories have returns --
  Southeast US and one other have zero returns
  consistent with near zero sales in those regions
- Date range matches sales data Jan 2015 - Jun 2017

Product Coverage:
- 130 unique products ever sold out of 293 in catalog
- 124 of 130 sold products have at least one return
- Only 6 products sold but never returned
- 148 products never sold therefore never returned
- Confirms exploratory analysis dead stock finding

Overall Return Rate:
- 1,828 units returned from 84,174 sold
- Overall return rate: 2.17%
- Healthy benchmark -- retail industry average
  is 8-10% for physical and 20-30% for e-commerce
- AdventureWorks customers are generally satisfied
  with products received

Data Quality:
- Zero unmatched returns -- all 1,809 transactions
  link correctly to Products table
- No orphaned return records detected
- Returns data confirmed clean and reliable

Limitation: Returns table has no CustomerKey --
cannot identify which customers are returning
products or whether returners are high or low
value customers. All return analysis limited to
product, territory and time dimensions only.
--------------*/

/*--------------------------------------------
   SECTION 2: RETURN RATE BY PRODUCT
   Goal: Identify which specific products
   have the highest return rates
   Note: Using subquery method to avoid
   JOIN multiplication error found in
   descriptive analysis Section 6
--------------------------------------------*/

-- Return rate by product -- top 20 highest rates
SELECT TOP 20
    p.ProductName,
    p.ProductPrice,
    COALESCE(s.TotalSold, 0) AS TotalSold,
    COALESCE(r.TotalReturned, 0) AS TotalReturned,
    ROUND(
        CAST(COALESCE(r.TotalReturned, 0) AS float) /
        NULLIF(CAST(COALESCE(s.TotalSold, 0) AS float), 0) * 100
    , 2) AS ReturnRatePct,
    ROUND(
        COALESCE(r.TotalReturned, 0) *
        p.ProductPrice
    , 2) AS ReturnedRevenue
FROM AdventureWorks_Products AS p
LEFT JOIN (
    SELECT ProductKey, SUM(OrderQuantity) AS TotalSold
    FROM AllSales
    GROUP BY ProductKey
) AS s ON p.ProductKey = s.ProductKey
LEFT JOIN (
    SELECT ProductKey, SUM(ReturnQuantity) AS TotalReturned
    FROM AdventureWorks_Returns
    GROUP BY ProductKey
) AS r ON p.ProductKey = r.ProductKey
WHERE r.TotalReturned > 0
ORDER BY ReturnRatePct DESC;

-- Products with most raw returns regardless of rate
SELECT TOP 20
    p.ProductName,
    p.ProductPrice,
    COALESCE(s.TotalSold, 0) AS TotalSold,
    COALESCE(r.TotalReturned, 0) AS TotalReturned,
    ROUND(
        CAST(COALESCE(r.TotalReturned, 0) AS float) /
        NULLIF(CAST(COALESCE(s.TotalSold, 0) AS float), 0) * 100
    , 2) AS ReturnRatePct
FROM AdventureWorks_Products AS p
LEFT JOIN (
    SELECT ProductKey, SUM(OrderQuantity) AS TotalSold
    FROM AllSales
    GROUP BY ProductKey
) AS s ON p.ProductKey = s.ProductKey
LEFT JOIN (
    SELECT ProductKey, SUM(ReturnQuantity) AS TotalReturned
    FROM AdventureWorks_Returns
    GROUP BY ProductKey
) AS r ON p.ProductKey = r.ProductKey
WHERE r.TotalReturned > 0
ORDER BY TotalReturned DESC;

-- Products never returned -- perfect record
SELECT
    p.ProductName,
    p.ProductPrice,
    COALESCE(s.TotalSold, 0) AS TotalSold
FROM AdventureWorks_Products AS p
LEFT JOIN (
    SELECT ProductKey, SUM(OrderQuantity) AS TotalSold
    FROM AllSales
    GROUP BY ProductKey
) AS s ON p.ProductKey = s.ProductKey
LEFT JOIN (
    SELECT ProductKey, SUM(ReturnQuantity) AS TotalReturned
    FROM AdventureWorks_Returns
    GROUP BY ProductKey
) AS r ON p.ProductKey = r.ProductKey
WHERE s.TotalSold > 0
AND r.TotalReturned IS NULL
ORDER BY TotalSold DESC;

/*--- SECTION 2 FINDINGS ---

Highest Return Rate Products:
- Road-650 Red highest rate at 11.76% (size 52)
- Road-650 Red appears in 5 sizes in top 20:
  sizes 44, 48, 52, 58 and 60 all elevated
  This is a MODEL level problem not size specific
  Something about Road-650 Red consistently
  disappoints customers across all sizes
- Mountain-100 appears in 4 variations in top 20:
  Silver 44, Black 44, Black 48, Silver 48
  Same pattern -- model wide issue
- Touring-3000 also appears multiple times
- Classic Vest and Womens Mountain Shorts both
  above 5% -- likely clothing sizing issues

Revenue Impact of High Rate Products:
- Road-150 Red, 44 highest revenue lost: $25,047
  Only 5.04% rate but $3,578 price means
  each return costs nearly $3,578 in revenue
- Road-150 Red, 48 second: $28,626 lost
- Touring-1000 Yellow, 50: $16,688 lost
- High price products have outsized revenue
  impact even at moderate return rates

Most Raw Returns -- Accessory Volume Effect:
- Water Bottle tops raw returns at 155 units
- Patch Kit, Mountain Tire Tube follow at 93-95
- All high raw return products are cheap accessories
- Their high numbers reflect high sales volume
  not a quality problem -- rates all under 2.5%
- Sport-100 Helmet slightly elevated at 3.33%
  across all three colors -- worth monitoring

Products Never Returned -- Only 6:
- Touring-3000 Blue, 44: 52 sold, 0 returned
- Road-650 Black, 44: 50 sold, 0 returned
- Mountain-500 Silver, 48: 49 sold, 0 returned
- Touring-3000 Yellow, 54: 47 sold, 0 returned
- Mountain-100 Silver, 38: 29 sold, 0 returned
- Mountain-100 Silver, 42: 25 sold, 0 returned

Critical Finding -- Mountain-100 Size Pattern:
- Mountain-100 Silver sizes 38 and 42: zero returns
- Mountain-100 Silver sizes 44 and 48: elevated rates
- Mountain-100 Black sizes 44 and 48: elevated rates
- Size 38 and 42 work perfectly
- Size 44 and above have consistent problems
- Strongly suggests a manufacturing or fit
  issue specific to larger Mountain-100 sizes
- This is actionable intelligence -- investigate
  production quality control for sizes 44+
--------------*/

/*--------------------------------------------
   SECTION 3: RETURN RATE BY CATEGORY
   Goal: Identify which product categories
   have structural return problems
--------------------------------------------*/

-- Return rate by category
SELECT
    cat.CategoryName,
    SUM(s.TotalSold) AS TotalSold,
    SUM(r.TotalReturned) AS TotalReturned,
    ROUND(
        CAST(SUM(r.TotalReturned) AS float) /
        NULLIF(CAST(SUM(s.TotalSold) AS float), 0) * 100
    , 2) AS ReturnRatePct,
    ROUND(
        SUM(r.TotalReturned * p.ProductPrice)
    , 2) AS ReturnedRevenue
FROM AdventureWorks_Products AS p
LEFT JOIN (
    SELECT ProductKey, SUM(OrderQuantity) AS TotalSold
    FROM AllSales
    GROUP BY ProductKey
) AS s ON p.ProductKey = s.ProductKey
LEFT JOIN (
    SELECT ProductKey, SUM(ReturnQuantity) AS TotalReturned
    FROM AdventureWorks_Returns
    GROUP BY ProductKey
) AS r ON p.ProductKey = r.ProductKey
LEFT JOIN AdventureWorks_Product_Subcategories AS sub
    ON p.ProductSubcategoryKey = sub.ProductSubcategoryKey
LEFT JOIN AdventureWorks_Product_Categories AS cat
    ON sub.ProductCategoryKey = cat.ProductCategoryKey
WHERE s.TotalSold > 0
GROUP BY cat.CategoryName
ORDER BY ReturnRatePct DESC;

-- Return rate by subcategory
SELECT
    sub.SubcategoryName,
    cat.CategoryName,
    SUM(s.TotalSold) AS TotalSold,
    SUM(r.TotalReturned) AS TotalReturned,
    ROUND(
        CAST(SUM(r.TotalReturned) AS float) /
        NULLIF(CAST(SUM(s.TotalSold) AS float), 0) * 100
    , 2) AS ReturnRatePct
FROM AdventureWorks_Products AS p
LEFT JOIN (
    SELECT ProductKey, SUM(OrderQuantity) AS TotalSold
    FROM AllSales
    GROUP BY ProductKey
) AS s ON p.ProductKey = s.ProductKey
LEFT JOIN (
    SELECT ProductKey, SUM(ReturnQuantity) AS TotalReturned
    FROM AdventureWorks_Returns
    GROUP BY ProductKey
) AS r ON p.ProductKey = r.ProductKey
LEFT JOIN AdventureWorks_Product_Subcategories AS sub
    ON p.ProductSubcategoryKey = sub.ProductSubcategoryKey
LEFT JOIN AdventureWorks_Product_Categories AS cat
    ON sub.ProductCategoryKey = cat.ProductCategoryKey
WHERE s.TotalSold > 0
AND r.TotalReturned > 0
GROUP BY sub.SubcategoryName, cat.CategoryName
ORDER BY ReturnRatePct DESC;

/*--- SECTION 3 FINDINGS ---

Category Return Rates:
- Bikes highest rate at 3.08%
- Clothing middle at 2.16%
- Accessories lowest at 1.95%
- Overall rate 2.17% confirmed healthy

Revenue Impact by Category:
- Bikes: $733,553 revenue lost to returns
  94.9% of return revenue impact despite
  being only 16.5% of units sold
- Accessories: $21,256 lost despite having
  most returns in raw volume (1,130 units)
- Clothing: only $10,468 lost -- cheap items
- One returned bike = ~34 returned accessories
  in revenue impact terms

Subcategory High Return Rates:
- Shorts: 4.24% -- highest in entire dataset
- Vests: 3.65%
- Hydration Packs: 3.60%
- Touring Bikes: 3.46%
- Road Bikes: 3.16%
- Helmets: 3.12%

Critical Finding -- Clothing Sizing Pattern:
- Every clothing subcategory above 2% except Caps
- Caps at 1.11% are one size fits all
- Shorts, Vests, Jerseys, Socks all elevated
- Only difference between Caps and other clothing
  is that Caps require no size selection
- Root cause conclusion: clothing returns are
  driven by incorrect size selection not
  product quality issues
- Solution: improve size guides, add size
  recommendation tool, review size chart accuracy

Road Bikes vs Mountain Bikes:
- Road Bikes: 3.16% return rate, $11.3M revenue
- Mountain Bikes: 2.95% return rate, $8.6M revenue
- Road Bikes have more SKUs (43 vs 32 variants)
- More size and color options increases risk of
  customers ordering wrong variant
- Road Bikes generate more revenue but also
  carry higher return risk

Touring Bikes:
- 3.46% return rate -- highest bike subcategory
- Only 2,025 units sold vs 7,049 Road Bikes
- Smaller volume means individual returns have
  larger impact on subcategory rate
- Worth monitoring but small absolute numbers

Low Return Rate Subcategories:
- Tires and Tubes: 1.79% despite 29,772 sold
- Fenders: 1.36%
- Caps: 1.11% -- lowest in entire dataset
- Consumable and non-fitted items consistently
  have lowest return rates confirming sizing
  as primary driver of returns
--------------*/

/*--------------------------------------------
   SECTION 4: RETURNS BY TERRITORY
   Goal: Identify geographic patterns
   in return behaviour
--------------------------------------------*/

-- Return rate by territory
-- Joining to AllSales to get units sold per territory
SELECT
    t.Region,
    t.Country,
    t.Continent,
    SUM(r.ReturnQuantity) AS TotalReturned,
    COUNT(r.ReturnQuantity) AS ReturnTransactions,
    SoldByTerritory.TotalSold,
    ROUND(
        CAST(SUM(r.ReturnQuantity) AS float) /
        NULLIF(SoldByTerritory.TotalSold, 0) * 100
    , 2) AS ReturnRatePct
FROM AdventureWorks_Returns AS r
LEFT JOIN AdventureWorks_Territories AS t
    ON r.TerritoryKey = t.SalesTerritoryKey
LEFT JOIN (
    SELECT TerritoryKey, SUM(OrderQuantity) AS TotalSold
    FROM AllSales
    GROUP BY TerritoryKey
) AS SoldByTerritory
    ON r.TerritoryKey = SoldByTerritory.TerritoryKey
GROUP BY t.Region, t.Country, t.Continent,
         SoldByTerritory.TotalSold
ORDER BY ReturnRatePct DESC;

-- Return rate by continent
SELECT
    t.Continent,
    SUM(r.ReturnQuantity) AS TotalReturned,
    SoldByContinent.TotalSold,
    ROUND(
        CAST(SUM(r.ReturnQuantity) AS float) /
        NULLIF(SoldByContinent.TotalSold, 0) * 100
    , 2) AS ReturnRatePct
FROM AdventureWorks_Returns AS r
LEFT JOIN AdventureWorks_Territories AS t
    ON r.TerritoryKey = t.SalesTerritoryKey
LEFT JOIN (
    SELECT
        t2.Continent,
        SUM(s.OrderQuantity) AS TotalSold
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Territories AS t2
        ON s.TerritoryKey = t2.SalesTerritoryKey
    GROUP BY t2.Continent
) AS SoldByContinent
    ON t.Continent = SoldByContinent.Continent
GROUP BY t.Continent, SoldByContinent.TotalSold
ORDER BY ReturnRatePct DESC;

/*--- SECTION 4 FINDINGS ---

Territory Return Rates:
- France highest at 2.37%
- Germany lowest meaningful territory at 2.05%
- Total range across all territories: 0.33%
- Remarkably consistent -- no territory has
  a return rate problem at any level

France Slightly Elevated:
- 2.37% vs dataset average of 2.17%
- Only 186 returns from 7,862 sales
- Absolute difference is minimal
- Likely natural variation not a real issue
- Does not warrant investigation at this scale

Australia Return Context:
- Most raw returns (404) due to most sales
- 2.25% rate -- second highest but normal
- Highest revenue impact in absolute terms
  due to high average order value
- Rate itself is not a concern

Continent Analysis:
- Pacific: 2.25%
- Europe: 2.17%
- North America: 2.14%
- Range across continents: 0.11%
- Returns are NOT a geographic problem
  at territory or continent level

Critical Finding -- Geography Is Not the Problem:
- Return rates consistent across 3 continents
- Consistent across 8 territories
- Consistent across different cultures and
  legal return policy environments
- This rules out geography, logistics,
  shipping damage and regional preferences
  as causes of returns
- Root causes are product specific:
  Road-650 Red model quality issue
  Mountain-100 size 44+ fit issue
  Clothing sizing across all garments
- These product issues affect all territories
  equally confirming they are manufacturing
  or design problems not regional ones

Note: Northeast US and Central US absent from
results -- zero returns consistent with near
zero sales in those territories
Note: Last row formatting issue in SSMS --
North America: 871 returned, 40,717 sold, 2.14%
--------------*/

/*--------------------------------------------
   SECTION 5: RETURNS OVER TIME
   Goal: Understand whether return rates
   are improving or worsening over time
--------------------------------------------*/

-- Returns by year with return rate
SELECT
    YEAR(r.ReturnDate) AS ReturnYear,
    SUM(r.ReturnQuantity) AS TotalReturned,
    COUNT(*) AS ReturnTransactions,
    SoldByYear.TotalSold,
    ROUND(
        CAST(SUM(r.ReturnQuantity) AS float) /
        NULLIF(SoldByYear.TotalSold, 0) * 100
    , 2) AS ReturnRatePct
FROM AdventureWorks_Returns AS r
LEFT JOIN (
    SELECT YEAR(OrderDate) AS SalesYear,
           SUM(OrderQuantity) AS TotalSold
    FROM AllSales
    GROUP BY YEAR(OrderDate)
) AS SoldByYear
    ON YEAR(r.ReturnDate) = SoldByYear.SalesYear
GROUP BY YEAR(r.ReturnDate), SoldByYear.TotalSold
ORDER BY ReturnYear;

-- Returns by month with return rate
SELECT
    YEAR(r.ReturnDate) AS ReturnYear,
    MONTH(r.ReturnDate) AS ReturnMonth,
    DATENAME(month, r.ReturnDate) AS MonthName,
    SUM(r.ReturnQuantity) AS TotalReturned,
    COUNT(*) AS ReturnTransactions,
    SoldByMonth.TotalSold,
    ROUND(
        CAST(SUM(r.ReturnQuantity) AS float) /
        NULLIF(SoldByMonth.TotalSold, 0) * 100
    , 2) AS ReturnRatePct
FROM AdventureWorks_Returns AS r
LEFT JOIN (
    SELECT
        YEAR(OrderDate) AS SalesYear,
        MONTH(OrderDate) AS SalesMonth,
        SUM(OrderQuantity) AS TotalSold
    FROM AllSales
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
) AS SoldByMonth
    ON YEAR(r.ReturnDate) = SoldByMonth.SalesYear
    AND MONTH(r.ReturnDate) = SoldByMonth.SalesMonth
GROUP BY YEAR(r.ReturnDate), MONTH(r.ReturnDate),
         DATENAME(month, r.ReturnDate),
         SoldByMonth.TotalSold
ORDER BY ReturnYear, ReturnMonth;

-- Quarter over quarter return rate trend
SELECT
    YEAR(r.ReturnDate) AS ReturnYear,
    DATEPART(quarter, r.ReturnDate) AS ReturnQuarter,
    SUM(r.ReturnQuantity) AS TotalReturned,
    SoldByQuarter.TotalSold,
    ROUND(
        CAST(SUM(r.ReturnQuantity) AS float) /
        NULLIF(SoldByQuarter.TotalSold, 0) * 100
    , 2) AS ReturnRatePct
FROM AdventureWorks_Returns AS r
LEFT JOIN (
    SELECT
        YEAR(OrderDate) AS SalesYear,
        DATEPART(quarter, OrderDate) AS SalesQuarter,
        SUM(OrderQuantity) AS TotalSold
    FROM AllSales
    GROUP BY YEAR(OrderDate), DATEPART(quarter, OrderDate)
) AS SoldByQuarter
    ON YEAR(r.ReturnDate) = SoldByQuarter.SalesYear
    AND DATEPART(quarter, r.ReturnDate) =
        SoldByQuarter.SalesQuarter
GROUP BY YEAR(r.ReturnDate),
         DATEPART(quarter, r.ReturnDate),
         SoldByQuarter.TotalSold
ORDER BY ReturnYear, ReturnQuarter;

/*--- SECTION 5 FINDINGS ---

Yearly Return Rates:
- 2015: 3.27% -- elevated due to bike only sales
- 2016: 2.13% -- dropped as accessories launched
- 2017: 2.15% -- stable continuation
- Decline from 2015 to 2016 explained entirely
  by product mix shift not quality improvement
- Accessories at 1.95% diluted the higher
  bike return rate of 3.08%

Monthly Pattern -- 2015 Volatility:
- April 2015: 6.86% highest month in dataset
- September 2015: 1.02% lowest month in dataset
- Extreme volatility is small sample size effect
- 2015 had only 2,630 sales -- a few returns
  in any month creates dramatic rate swings
- Individual 2015 monthly rates not statistically
  reliable due to small denominator

Critical Finding -- July 2016 Stabilisation:
- Jan-Jun 2016: rates volatile 1.72% to 3.31%
- Jul 2016 onwards: rates locked 2.01% to 2.30%
- 12 consecutive months within 0.29% range
- Accessories launch created product diversity
  that stabilised the blended return rate
- Business reached natural return equilibrium
  once product mix became diverse

Quarterly Trend Analysis:
- 2015 Q2: 4.66% highest quarter -- small sample
- 2016 Q3 onwards: 2.07% to 2.23% every quarter
- Five consecutive quarters within 0.16% range
- Return rate has effectively locked at ~2.1%
- No deterioration trend detected
- No improvement trend detected either --
  rate appears to have plateaued at 2.1%

No Worsening Trend:
- Despite massive volume growth from 2015 to 2017
- Despite new product categories launching
- Despite new territories coming online
- Return rate has remained stable and healthy
- Business is not experiencing a returns crisis

Limitation: Cannot determine whether returns
are happening within days or months of purchase
without matching individual orders to returns.
Section 7 average days to return attempts this
but uses approximation due to no CustomerKey
in Returns table.
--------------*/

/*--------------------------------------------
   SECTION 6: RETURN REVENUE IMPACT
   Goal: Quantify how much revenue is lost
   to returns and which products cost most
--------------------------------------------*/

-- Total revenue impact of returns
SELECT
    SUM(r.ReturnQuantity * p.ProductPrice) AS TotalReturnedRevenue,
    SUM(s.TotalRevenue) AS TotalSalesRevenue,
    ROUND(
        SUM(r.ReturnQuantity * p.ProductPrice) /
        NULLIF(SUM(s.TotalRevenue), 0) * 100
    , 2) AS ReturnRevenueImpactPct
FROM AdventureWorks_Returns AS r
LEFT JOIN AdventureWorks_Products AS p
    ON r.ProductKey = p.ProductKey
CROSS JOIN (
    SELECT SUM(s.OrderQuantity * p2.ProductPrice) AS TotalRevenue
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Products AS p2
        ON s.ProductKey = p2.ProductKey
) AS s;

-- Revenue lost per category from returns
SELECT
    cat.CategoryName,
    SUM(r.ReturnQuantity) AS TotalReturned,
    ROUND(SUM(r.ReturnQuantity * p.ProductPrice), 2) AS ReturnedRevenue,
    ROUND(SUM(s.TotalSold * p.ProductPrice), 2) AS TotalSoldRevenue,
    ROUND(
        SUM(r.ReturnQuantity * p.ProductPrice) /
        NULLIF(SUM(s.TotalSold * p.ProductPrice), 0) * 100
    , 2) AS RevenueLostPct
FROM AdventureWorks_Products AS p
LEFT JOIN (
    SELECT ProductKey, SUM(OrderQuantity) AS TotalSold
    FROM AllSales
    GROUP BY ProductKey
) AS s ON p.ProductKey = s.ProductKey
LEFT JOIN (
    SELECT ProductKey, SUM(ReturnQuantity) AS ReturnQuantity
    FROM AdventureWorks_Returns
    GROUP BY ProductKey
) AS r ON p.ProductKey = r.ProductKey
LEFT JOIN AdventureWorks_Product_Subcategories AS sub
    ON p.ProductSubcategoryKey = sub.ProductSubcategoryKey
LEFT JOIN AdventureWorks_Product_Categories AS cat
    ON sub.ProductCategoryKey = cat.ProductCategoryKey
WHERE s.TotalSold > 0
AND r.ReturnQuantity > 0
GROUP BY cat.CategoryName
ORDER BY ReturnedRevenue DESC;

-- Top 10 products by revenue lost to returns
SELECT TOP 10
    p.ProductName,
    p.ProductPrice,
    r.TotalReturned,
    ROUND(r.TotalReturned * p.ProductPrice, 2) AS ReturnedRevenue,
    s.TotalSold,
    ROUND(
        CAST(r.TotalReturned AS float) /
        NULLIF(s.TotalSold, 0) * 100
    , 2) AS ReturnRatePct
FROM AdventureWorks_Products AS p
LEFT JOIN (
    SELECT ProductKey, SUM(OrderQuantity) AS TotalSold
    FROM AllSales
    GROUP BY ProductKey
) AS s ON p.ProductKey = s.ProductKey
LEFT JOIN (
    SELECT ProductKey, SUM(ReturnQuantity) AS TotalReturned
    FROM AdventureWorks_Returns
    GROUP BY ProductKey
) AS r ON p.ProductKey = r.ProductKey
WHERE r.TotalReturned > 0
ORDER BY ReturnedRevenue DESC;

/*--- SECTION 6 FINDINGS ---

Total Revenue Impact:
- Total revenue lost to returns: $765,278
- Total sales revenue: $24,914,586
- Return revenue impact: 3.07%
  (corrected query -- original CROSS JOIN
  produced incorrect $45B total revenue figure
  due to row multiplication error)
- $765K lost is significant but manageable
  at 3.07% of total revenue

Note on Query Error:
- Original total revenue impact query used
  CROSS JOIN which multiplied incorrectly
- Corrected to use confirmed $24.9M total
  revenue from descriptive analysis
- Category and product level queries unaffected
  as they did not use the same CROSS JOIN

Category Revenue Lost:
- Bikes: $733,553 lost -- 3.15% of bike revenue
- Clothing: $10,468 lost -- 2.86% of clothing revenue
- Accessories: $21,256 lost -- 2.34% of accessory revenue
- Bikes represent 95.8% of all return revenue loss
  despite being 16.5% of units sold
- Returning one bike costs same as returning
  approximately 34 accessories in revenue terms

Top 10 Revenue Lost -- Mountain-200 Discovery:
- Mountain-200 dominates revenue lost list
  with 5 variations in top 10
- Mountain-200 Black, 42 highest at $43,031 lost
- Mountain-200 did NOT appear in highest return
  RATE list -- rate is moderate 2.10% to 3.49%
- Appears here because of high sales volume --
  high volume times moderate rate equals
  large absolute revenue loss
- This is the volume effect on revenue impact

Road-150 Red Revenue Impact:
- Road-150 Red, 48: $28,626 lost (4.47% rate)
- Road-150 Red, 44: $25,047 lost (5.04% rate)
- Highest price product at $3,578 per unit
- Each return costs $3,578 in revenue
- Only 15 total returns across both sizes
  but revenue impact is disproportionate

Two Types of Return Revenue Problem:
1. Volume problem: Mountain-200 -- moderate rate
   but high sales volume creates large losses
   Fix: marginal rate improvement on high
   volume products has outsized revenue impact
2. Rate problem: Road-150 Red, Road-650 Red --
   high rates on premium priced products
   Fix: investigate and fix product quality
   issues to eliminate the rate problem entirely

Key Insight:
- Fixing Road-650 Red return problem (11.76% rate)
  would save approximately $4,194 per 51 units
- Fixing Mountain-200 return rate by just 1%
  would save approximately $20,000+ per year
  given its high sales volume
- Both problems are worth fixing but for
  different reasons
--------------*/

/*--------------------------------------------
   SECTION 7: RETURN PATTERN ANALYSIS
   Goal: Find patterns that explain why
   returns happen and when they peak
--------------------------------------------*/

-- Day of week return pattern
-- Do returns concentrate on certain days
SELECT
    DATEPART(weekday, ReturnDate) AS DayNumber,
    DATENAME(weekday, ReturnDate) AS DayName,
    COUNT(*) AS ReturnTransactions,
    SUM(ReturnQuantity) AS UnitsReturned
FROM AdventureWorks_Returns
GROUP BY DATEPART(weekday, ReturnDate),
         DATENAME(weekday, ReturnDate)
ORDER BY DayNumber;

-- Average days between sale and return
-- How long before customers return products
SELECT
    p.ProductName,
    cat.CategoryName,
    COUNT(*) AS ReturnCount,
    ROUND(AVG(CAST(DATEDIFF(day, s.OrderDate, r.ReturnDate)
        AS float)), 0) AS AvgDaysToReturn,
    MIN(DATEDIFF(day, s.OrderDate, r.ReturnDate))
        AS MinDaysToReturn,
    MAX(DATEDIFF(day, s.OrderDate, r.ReturnDate))
        AS MaxDaysToReturn
FROM AdventureWorks_Returns AS r
LEFT JOIN AdventureWorks_Products AS p
    ON r.ProductKey = p.ProductKey
LEFT JOIN AdventureWorks_Product_Subcategories AS sub
    ON p.ProductSubcategoryKey = sub.ProductSubcategoryKey
LEFT JOIN AdventureWorks_Product_Categories AS cat
    ON sub.ProductCategoryKey = cat.ProductCategoryKey
LEFT JOIN AllSales AS s
    ON r.ProductKey = s.ProductKey
    AND r.TerritoryKey = s.TerritoryKey
    AND s.OrderDate <= r.ReturnDate
GROUP BY p.ProductName, cat.CategoryName
HAVING COUNT(*) >= 5
ORDER BY AvgDaysToReturn ASC;

-- Return concentration -- are returns spread evenly
-- or concentrated in specific products
SELECT
    CASE
        WHEN TotalReturned >= 100 THEN '100+ returns'
        WHEN TotalReturned >= 50  THEN '50-99 returns'
        WHEN TotalReturned >= 20  THEN '20-49 returns'
        WHEN TotalReturned >= 10  THEN '10-19 returns'
        WHEN TotalReturned >= 5   THEN '5-9 returns'
        ELSE '1-4 returns'
    END AS ReturnBand,
    COUNT(*) AS NumberOfProducts,
    SUM(TotalReturned) AS TotalUnitsReturned,
    ROUND(
        CAST(SUM(TotalReturned) AS float) /
        NULLIF((SELECT SUM(ReturnQuantity)
                FROM AdventureWorks_Returns), 0) * 100
    , 2) AS PctOfAllReturns
FROM (
    SELECT ProductKey, SUM(ReturnQuantity) AS TotalReturned
    FROM AdventureWorks_Returns
    GROUP BY ProductKey
) ProductReturns
GROUP BY
    CASE
        WHEN TotalReturned >= 100 THEN '100+ returns'
        WHEN TotalReturned >= 50  THEN '50-99 returns'
        WHEN TotalReturned >= 20  THEN '20-49 returns'
        WHEN TotalReturned >= 10  THEN '10-19 returns'
        WHEN TotalReturned >= 5   THEN '5-9 returns'
        ELSE '1-4 returns'
    END
ORDER BY MIN(TotalReturned) DESC;

/*--- SECTION 7 FINDINGS ---

Day of Week Pattern:
- Returns flat across all 7 days of the week
- Wednesday highest at 280 transactions
- Thursday lowest at 232 transactions
- Only 20% difference between best and worst day
- Mirrors flat sales day of week pattern exactly
- Confirms online retail behaviour --
  customers return whenever convenient

Average Days to Return:
- Bikes returned fastest: 29-99 days average
- Accessories returned slowest: 99-120 days average
- Pattern makes intuitive sense:
  Bike buyers know within weeks if fit is wrong
  Accessory buyers may not use product immediately
  and discover issues months later

Return Speed by Category:
- Mountain-100 series fastest returns: 29-61 days
  Customers quickly discover fit problems
- Road-150 Red: 37-63 days -- size issues found fast
- Accessories average 99-120 days -- delayed returns
  suggest products tried and tested over time
  before deciding to return

Extreme Return Timing Outliers:
- Road-650 Red, 48: maximum 517 days after purchase
- Road-550-W Yellow, 38: maximum 727 days
- Mountain-200 Black, 46: maximum 720 days
- Returns 700+ days after purchase are anomalous
- Likely data entry errors, policy exploitation
  or system misuse rather than genuine returns
- These outliers inflate average days figures
  for affected products

Note on ReturnCount Column:
- ReturnCount figures in average days query are
  inflated due to JOIN multiplication --
  each return matched against every sale of
  same product in same territory
- Water Bottle shows 44,663 vs actual 155 returns
- Average days figures remain valid as they
  average across all matched pairs
- ReturnCount column should be ignored --
  use actual return counts from Section 2

Return Concentration -- The Critical Finding:
- Only 1 product has 100+ returns (8.48% of total)
- Top 10 products generate 42.94% of all returns
- Top 22 products generate 64.60% of all returns
- 45 products have only 1-4 returns (5.47% of total)
- Returns are highly concentrated in a small
  number of products

Strategic Implication of Concentration:
- Fixing the top 10 return products would
  eliminate 42.94% of all return volume
- Fixing top 22 products eliminates 64.60%
- This is highly actionable -- a targeted
  quality improvement program on a small
  number of products would dramatically
  reduce total return burden
- Much more efficient than broad quality
  initiatives across all 124 returned products

Products to Prioritise for Quality Review:
Based on combined rate, revenue impact and
concentration analysis:
1. Road-650 Red (all sizes) -- 11.76% rate,
   model wide problem, multiple sizes affected
2. Mountain-100 (sizes 44+) -- elevated rate,
   size specific manufacturing issue confirmed
3. Mountain-200 (all sizes) -- moderate rate but
   highest revenue loss due to high volume
4. Road-150 Red -- high rate and high price
   means each return costs $3,578 in revenue
5. Clothing (all garments with sizing) --
   systemic sizing issue across entire category
--------------*/

/*--- SECTION 7 SUMMARY ---
Three actionable insights from pattern analysis:

1. Returns are highly concentrated --
   fix 22 products to eliminate 65% of returns

2. Bike returns happen fast (under 60 days) --
   fit and sizing issues discovered immediately
   Better size guidance at point of purchase
   would prevent many bike returns

3. Accessory returns happen slowly (100+ days) --
   customers try before deciding to return
   Product quality or expectation mismatch
   rather than sizing issue

Return rate of 2.17% is healthy and stable --
the business does not have a returns crisis
but has specific product level problems
that are worth fixing for revenue impact
--------------*/