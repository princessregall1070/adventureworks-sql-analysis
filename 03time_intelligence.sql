/*============================================
   ADVENTUREWORKS TIME INTELLIGENCE ANALYSIS
   Analyst: Your Name
   Date: April 2026
   Database: AdventureWorks
   Purpose: Analyse revenue trends over time
   using OrderDate from AllSales view.
   Note: Calendar table only contains year values
   (2015, 2016, 2017) and cannot be used.
   All time intelligence built from OrderDate.
=============================================*/

/*--------------------------------------------
   SECTION 1: YEARLY PERFORMANCE
   Goal: Understand revenue and volume trends
   across each full year
--------------------------------------------*/
-- Total revenue and profit by year
SELECT
    YEAR(s.OrderDate) AS SalesYear,
    COUNT(DISTINCT s.OrderNumber) AS TotalOrders,
    SUM(s.OrderQuantity) AS TotalUnitsSold,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue,
    ROUND(SUM(s.OrderQuantity * p.ProductCost), 2) AS TotalCost,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice) -
    SUM(s.OrderQuantity * p.ProductCost), 2) AS TotalProfit,
    ROUND(
        (SUM(s.OrderQuantity * p.ProductPrice) -
        SUM(s.OrderQuantity * p.ProductCost)) /
        NULLIF(SUM(s.OrderQuantity * p.ProductPrice), 0) * 100
    , 2) AS ProfitMarginPct
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY YEAR(s.OrderDate)
ORDER BY SalesYear;

-- Year over year revenue growth
SELECT
    SalesYear,
    TotalRevenue,
    LAG(TotalRevenue) OVER (ORDER BY SalesYear) AS PriorYearRevenue,
    ROUND(
        (TotalRevenue - LAG(TotalRevenue) OVER (ORDER BY SalesYear)) /
        NULLIF(LAG(TotalRevenue) OVER (ORDER BY SalesYear), 0) * 100
    , 2) AS YoYGrowthPct
FROM (
    SELECT
        YEAR(s.OrderDate) AS SalesYear,
        ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Products AS p
        ON s.ProductKey = p.ProductKey
    GROUP BY YEAR(s.OrderDate)
) YearlyTotals
ORDER BY SalesYear;

/*--- SECTION 1 FINDINGS ---

Revenue and Profit by Year:
- 2015: $6.4M revenue, 40.62% profit margin
  Orders = Units (2630) -- every order was 1 unit
- 2016: $9.3M revenue, 42.55% profit margin
  Margin improvement as product mix shifted
  Avg 3.39 units per order vs 1.0 in 2015
- 2017: $9.2M revenue in first half only
  42.34% margin -- stable and consistent

Year Over Year Growth:
- 2015 to 2016: +45.58% revenue growth
- 2016 to 2017: -1.49% -- MISLEADING figure
  2017 covers January to June only
  2017 H1 already at 98.5% of full year 2016
  Full year 2017 projected ~$18.4M if H2 matches H1

Limitation: 2017 YoY comparison not valid due to
partial year. All 2017 figures must note H1 only.
--------------*/

/*--------------------------------------------
   SECTION 2: QUARTERLY PERFORMANCE
   Goal: Identify quarterly patterns and
   understand Q4 acceleration trend
--------------------------------------------*/

-- Revenue by quarter across all years
SELECT
    YEAR(s.OrderDate) AS SalesYear,
    DATEPART(quarter, s.OrderDate) AS SalesQuarter,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue,
    COUNT(DISTINCT s.OrderNumber) AS TotalOrders
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY YEAR(s.OrderDate), DATEPART(quarter, s.OrderDate)
ORDER BY SalesYear, SalesQuarter;

-- Quarter over quarter revenue growth within each year
SELECT
    SalesYear,
    SalesQuarter,
    TotalRevenue,
    LAG(TotalRevenue) OVER (
        PARTITION BY SalesYear
        ORDER BY SalesQuarter
    ) AS PriorQuarterRevenue,
    ROUND(
        (TotalRevenue - LAG(TotalRevenue) OVER (
            PARTITION BY SalesYear ORDER BY SalesQuarter)) /
        NULLIF(LAG(TotalRevenue) OVER (
            PARTITION BY SalesYear ORDER BY SalesQuarter), 0) * 100
    , 2) AS QoQGrowthPct
FROM (
    SELECT
        YEAR(s.OrderDate) AS SalesYear,
        DATEPART(quarter, s.OrderDate) AS SalesQuarter,
        ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Products AS p
        ON s.ProductKey = p.ProductKey
    GROUP BY YEAR(s.OrderDate), DATEPART(quarter, s.OrderDate)
) QuarterlyTotals
ORDER BY SalesYear, SalesQuarter;

-- Same quarter comparison across years
-- How did Q1 2017 compare to Q1 2016?
SELECT
    DATEPART(quarter, s.OrderDate) AS SalesQuarter,
    YEAR(s.OrderDate) AS SalesYear,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY DATEPART(quarter, s.OrderDate), YEAR(s.OrderDate)
ORDER BY SalesQuarter, SalesYear;

/*--- SECTION 2 FINDINGS ---

2015 Quarterly Pattern:
- Orders increased every quarter but revenue fell
- Q1 avg order value $3,219 vs Q4 avg $1,749
- Product mix shifted within 2015 itself --
  early 2015 dominated by premium bikes,
  later 2015 shows cheaper products entering

2016 Quarterly Pattern:
- Q1 and Q2 2016 lower than equivalent 2015 quarters
- Q3 2016 grew 63.39% over Q2 -- largest single
  quarter jump in entire dataset
- Q4 2016 grew further 47.69% -- sustained momentum
- Something significant happened in mid 2016 --
  possible product launch or territory expansion

2017 Quarterly Pattern:
- Q1 2017 ($4.06M) larger than any full quarter
  in 2015 or early 2016
- Q2 2017 ($5.12M) highest single quarter on record
- QoQ growth of 26.12% from Q1 to Q2 2017

Same Quarter Comparison:
- Q1 and Q2 2016 were LOWER than 2015 equivalents
- Q3 and Q4 2016 drove the full year growth
- Q1 2017 was +194.6% above Q1 2016
- Q2 2017 was +225.7% above Q2 2016
- Growth is not linear -- comes in dramatic bursts

Limitation: 2017 Q3 and Q4 not available.
Cannot confirm if Q4 acceleration pattern
continued into 2017.
--------------*/


/*--------------------------------------------
   SECTION 3: MONTHLY PERFORMANCE
   Goal: Identify seasonality patterns and
   find strongest and weakest months
--------------------------------------------*/

-- Revenue by month across all years
SELECT
    YEAR(s.OrderDate) AS SalesYear,
    MONTH(s.OrderDate) AS MonthNumber,
    DATENAME(month, s.OrderDate) AS MonthName,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue,
    COUNT(DISTINCT s.OrderNumber) AS TotalOrders
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY YEAR(s.OrderDate), MONTH(s.OrderDate), 
         DATENAME(month, s.OrderDate)
ORDER BY SalesYear, MonthNumber;

-- Month over month revenue growth
SELECT
    SalesYear,
    MonthNumber,
    MonthName,
    TotalRevenue,
    LAG(TotalRevenue) OVER (ORDER BY SalesYear, MonthNumber) AS PriorMonthRevenue,
    ROUND(
        (TotalRevenue - LAG(TotalRevenue) OVER (
            ORDER BY SalesYear, MonthNumber)) /
        NULLIF(LAG(TotalRevenue) OVER (
            ORDER BY SalesYear, MonthNumber), 0) * 100
    , 2) AS MoMGrowthPct
FROM (
    SELECT
        YEAR(s.OrderDate) AS SalesYear,
        MONTH(s.OrderDate) AS MonthNumber,
        DATENAME(month, s.OrderDate) AS MonthName,
        ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Products AS p
        ON s.ProductKey = p.ProductKey
    GROUP BY YEAR(s.OrderDate), MONTH(s.OrderDate),
             DATENAME(month, s.OrderDate)
) MonthlyTotals
ORDER BY SalesYear, MonthNumber;

-- Same month comparison across years
-- How did January 2017 compare to January 2016?
SELECT
    MONTH(s.OrderDate) AS MonthNumber,
    DATENAME(month, s.OrderDate) AS MonthName,
    YEAR(s.OrderDate) AS SalesYear,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY MONTH(s.OrderDate), DATENAME(month, s.OrderDate),
         YEAR(s.OrderDate)
ORDER BY MonthNumber, SalesYear;

-- Best and worst month per year
SELECT
    SalesYear,
    MonthName,
    TotalRevenue,
    RANK() OVER (
        PARTITION BY SalesYear
        ORDER BY TotalRevenue DESC
    ) AS RevenueRank
FROM (
    SELECT
        YEAR(s.OrderDate) AS SalesYear,
        MONTH(s.OrderDate) AS MonthNumber,
        DATENAME(month, s.OrderDate) AS MonthName,
        ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Products AS p
        ON s.ProductKey = p.ProductKey
    GROUP BY YEAR(s.OrderDate), MONTH(s.OrderDate),
             DATENAME(month, s.OrderDate)
) MonthlyTotals
ORDER BY SalesYear, RevenueRank;

/*--- SECTION 3 FINDINGS ---

2015 Monthly Pattern:
- Peaked in June ($669,988) then collapsed
- September worst month at $344,062
- November worst month overall at $326,611
- December recovered strongly +72.61%
- Mid-year collapse suggests seasonal demand
  for premium bikes concentrated in spring

2016 Monthly Pattern:
- Jan-Jun 2016 ($2.55M) LOWER than Jan-Jun 2015
- July 2016 jumped 52.74% in single month --
  most important inflection point in dataset
- Aug through Dec 2016 explosive and sustained
- December 2016 best single month at $1.63M
- Something fundamental changed in July 2016

2017 Monthly Pattern:
- Every single month grew over prior month
- No collapses or dips -- pure upward momentum
- June 2017 ($1.83M) highest single month ever
- January post-holiday dip is normal behaviour

Same Month Comparison:
- Every 2017 month approximately 3x equivalent
  2016 month
- June 2017 is 242% higher than June 2016
- Growth is consistent across all 6 comparable months

Seasonality Finding:
- 2015: Peaked June, worst November
- 2016: Peaked December, worst January
- 2017: Peaked June (partial year)
- Seasonal pattern reversed between 2015 and 2016
- Consistent with product mix shift from premium
  bikes (spring demand) to year-round accessories
  and mid-range bikes

Critical Finding -- July 2016 Inflection:
- Revenue more than doubled between H1 and H2 2016
- July 2016 single month +52.74% with no prior signal
- Likely caused by new product line launch,
  territory expansion or major marketing event
- Warrants investigation if business context available

Limitation: 2017 only covers January through June.
Cannot confirm if December 2017 would continue
the strong Q4 pattern established in 2016.
--------------*/

/*--------------------------------------------
   SECTION 4: RUNNING TOTALS
   Goal: Show cumulative revenue building
   up through each year
--------------------------------------------*/

-- Cumulative revenue within each year
SELECT
    SalesYear,
    MonthNumber,
    MonthName,
    MonthlyRevenue,
    ROUND(SUM(MonthlyRevenue) OVER (
        PARTITION BY SalesYear
        ORDER BY MonthNumber
    ), 2) AS CumulativeRevenue
FROM (
    SELECT
        YEAR(s.OrderDate) AS SalesYear,
        MONTH(s.OrderDate) AS MonthNumber,
        DATENAME(month, s.OrderDate) AS MonthName,
        ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS MonthlyRevenue
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Products AS p
        ON s.ProductKey = p.ProductKey
    GROUP BY YEAR(s.OrderDate), MONTH(s.OrderDate),
             DATENAME(month, s.OrderDate)
) MonthlyTotals
ORDER BY SalesYear, MonthNumber;

-- Cumulative revenue across all years combined
SELECT
    SalesYear,
    MonthNumber,
    MonthName,
    MonthlyRevenue,
    ROUND(SUM(MonthlyRevenue) OVER (
        ORDER BY SalesYear, MonthNumber
    ), 2) AS CumulativeRevenueAllYears
FROM (
    SELECT
        YEAR(s.OrderDate) AS SalesYear,
        MONTH(s.OrderDate) AS MonthNumber,
        DATENAME(month, s.OrderDate) AS MonthName,
        ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS MonthlyRevenue
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Products AS p
        ON s.ProductKey = p.ProductKey
    GROUP BY YEAR(s.OrderDate), MONTH(s.OrderDate),
             DATENAME(month, s.OrderDate)
) MonthlyTotals
ORDER BY SalesYear, MonthNumber;

/*--- SECTION 4 FINDINGS ---

Cumulative Within Each Year:
- 2015 reached $9M in 12 months (full year)
- 2016 reached $9M in 12 months (full year)
- 2017 reached $9M in just 6 months (half year)
- 2017 pace is exactly double 2015 and 2016

Mid Year Comparison (end of June):
- 2015 at end of June: $3,743,653
- 2016 at end of June: $2,952,867 -- BEHIND 2015
- 2017 at end of June: $9,185,449 -- 2.45x 2015
- 2016 only surpassed 2015 due to H2 explosion
- Without H2 2016 would have been worse than 2015

Cumulative All Years Milestones:
- $10M reached: July 2016 (19 months in)
- $20M reached: March 2017 (27 months in)
- $24.9M reached: June 2017 (30 months total)
- First $10M took 19 months
- Second $10M took only 8 months
- Business accelerating dramatically over time

Key Finding:
- Business effectively operates in two phases:
  Phase 1 (Jan 2015 - Jun 2016): slow growth,
  revenue between $300K-$670K per month
  Phase 2 (Jul 2016 - Jun 2017): rapid growth,
  revenue between $800K-$1.83M per month
- The July 2016 inflection point marks the
  transition between these two phases

Limitation: Last row formatting issue in SSMS --
20176 June 1826987.14 24914586.93 is correct as:
SalesYear: 2017, Month: 6, June,
MonthlyRevenue: $1,826,987.14,
CumulativeAllYears: $24,914,586.93
--------------*/

/*--------------------------------------------
   SECTION 5: SEASONALITY ANALYSIS
   Goal: Find patterns that repeat across
   years to identify predictable busy and
   slow periods
--------------------------------------------*/

-- Average revenue by month across all years
-- Shows which months are consistently strong
SELECT
    MonthlyTotals.MonthNumber,
    MonthlyTotals.MonthName,
    ROUND(AVG(MonthlyTotals.MonthlyRevenue), 2) AS AvgMonthlyRevenue,
    ROUND(MIN(MonthlyTotals.MonthlyRevenue), 2) AS MinMonthlyRevenue,
    ROUND(MAX(MonthlyTotals.MonthlyRevenue), 2) AS MaxMonthlyRevenue
FROM (
    SELECT
        MONTH(s.OrderDate) AS MonthNumber,
        DATENAME(month, s.OrderDate) AS MonthName,
        YEAR(s.OrderDate) AS SalesYear,
        SUM(s.OrderQuantity * p.ProductPrice) AS MonthlyRevenue
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Products AS p
        ON s.ProductKey = p.ProductKey
    GROUP BY MONTH(s.OrderDate), DATENAME(month, s.OrderDate),
             YEAR(s.OrderDate)
) MonthlyTotals
GROUP BY MonthlyTotals.MonthNumber, MonthlyTotals.MonthName
ORDER BY MonthlyTotals.MonthNumber;

-- Average revenue by quarter across all years
SELECT
    QuarterlyTotals.SalesQuarter,
    ROUND(AVG(QuarterlyTotals.QuarterlyRevenue), 2) AS AvgQuarterlyRevenue,
    ROUND(MIN(QuarterlyTotals.QuarterlyRevenue), 2) AS MinQuarterlyRevenue,
    ROUND(MAX(QuarterlyTotals.QuarterlyRevenue), 2) AS MaxQuarterlyRevenue
FROM (
    SELECT
        DATEPART(quarter, s.OrderDate) AS SalesQuarter,
        YEAR(s.OrderDate) AS SalesYear,
        SUM(s.OrderQuantity * p.ProductPrice) AS QuarterlyRevenue
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Products AS p
        ON s.ProductKey = p.ProductKey
    GROUP BY DATEPART(quarter, s.OrderDate), YEAR(s.OrderDate)
) QuarterlyTotals
GROUP BY QuarterlyTotals.SalesQuarter
ORDER BY QuarterlyTotals.SalesQuarter;

-- Day of week analysis
-- Which days generate the most orders
SELECT
    DATEPART(weekday, s.OrderDate) AS DayNumber,
    DATENAME(weekday, s.OrderDate) AS DayName,
    COUNT(DISTINCT s.OrderNumber) AS TotalOrders,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY DATEPART(weekday, s.OrderDate),
         DATENAME(weekday, s.OrderDate)
ORDER BY DayNumber;

-- Average revenue by month across all years
-- Shows which months are consistently strong
MonthNumber	MonthName	AvgMonthlyRevenue	MinMonthlyRevenue	MaxMonthlyRevenue
1	January	764039.02	432425.74	1274378.67
2	February	781876.78	474162.79	1339241.3
3	March	854664.71	471961.88	1448596.13
4	April	892045.06	494957.42	1527813.73
5	May	991097.72	545534.75	1768432.51
6	June	1010266.93	533824.99	1826987.14
7	July	650735.74	486115.01	815356.47
8	August	670323.11	536452.82	804193.39
9	September	648403.19	344062.88	952743.49
10	October	717048.83	404276.6	1029821.05
11	November	730262.1	326611.16	1133913.05
12	December	1099535.17	563761.53	1635308.81


-- Average revenue by month across all years
-- Shows which months are consistently strong
MonthNumber	MonthName	AvgMonthlyRevenue	MinMonthlyRevenue	MaxMonthlyRevenue
1	January	764039.02	432425.74	1274378.67
2	February	781876.78	474162.79	1339241.3
3	March	854664.71	471961.88	1448596.13
4	April	892045.06	494957.42	1527813.73
5	May	991097.72	545534.75	1768432.51
6	June	1010266.93	533824.99	1826987.14
7	July	650735.74	486115.01	815356.47
8	August	670323.11	536452.82	804193.39
9	September	648403.19	344062.88	952743.49
10	October	717048.83	404276.6	1029821.05
11	November	730262.1	326611.16	1133913.05
12	December	1099535.17	563761.53	1635308.81

-- Average revenue by quarter across all years
SalesQuarter	AvgQuarterlyRevenue	MinQuarterlyRevenue	MaxQuarterlyRevenue
1	2400580.51	1378550.42	4062216.1
2	2893409.72	1574317.16	5123233.38
3	1969462.03	1366630.71	2572293.35
4	2546846.1	1294649.29	3799042.91

-- Day of week analysis
-- Which days generate the most orders
DayNumber	DayName	TotalOrders	TotalRevenue
1	Sunday	3487	3469715.54
2	Monday	3702	3625047.01
3	Tuesday	3617	3581061.92
4	Wednesday	3688	3660068.34
5	Thursday	3481	3484857.31
6	Friday	3637	3574587.1
7	Saturday	3552	3519249.71

/*--------------------------------------------
   SECTION 6: REVENUE TRENDS BY CATEGORY
   Goal: Understand how each product category
   performs over time
--------------------------------------------*/

-- Monthly revenue by product category
SELECT
    YEAR(s.OrderDate) AS SalesYear,
    MONTH(s.OrderDate) AS MonthNumber,
    DATENAME(month, s.OrderDate) AS MonthName,
    cat.CategoryName,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
LEFT JOIN AdventureWorks_Product_Subcategories AS sub
    ON p.ProductSubcategoryKey = sub.ProductSubcategoryKey
LEFT JOIN AdventureWorks_Product_Categories AS cat
    ON sub.ProductCategoryKey = cat.ProductCategoryKey
GROUP BY YEAR(s.OrderDate), MONTH(s.OrderDate),
         DATENAME(month, s.OrderDate), cat.CategoryName
ORDER BY SalesYear, MonthNumber, TotalRevenue DESC;

-- Yearly revenue by product category
SELECT
    YEAR(s.OrderDate) AS SalesYear,
    cat.CategoryName,
    ROUND(SUM(s.OrderQuantity * p.ProductPrice), 2) AS TotalRevenue,
    ROUND(
        SUM(s.OrderQuantity * p.ProductPrice) /
        NULLIF(SUM(SUM(s.OrderQuantity * p.ProductPrice)) OVER (
            PARTITION BY YEAR(s.OrderDate)
        ), 0) * 100
    , 2) AS PctOfYearlyRevenue
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
LEFT JOIN AdventureWorks_Product_Subcategories AS sub
    ON p.ProductSubcategoryKey = sub.ProductSubcategoryKey
LEFT JOIN AdventureWorks_Product_Categories AS cat
    ON sub.ProductCategoryKey = cat.ProductCategoryKey
GROUP BY YEAR(s.OrderDate), cat.CategoryName
ORDER BY SalesYear, TotalRevenue DESC;

/*--- SECTION 6 FINDINGS ---

Critical Discovery -- The July 2016 Inflection Explained:
- 2015 entire year: 100% bikes, zero accessories,
  zero clothing
- July 2016: First appearance of Accessories and
  Clothing in sales data
- Accessories and Clothing launched simultaneously
  in July 2016 -- not a sales surge but a
  product line expansion
- This single fact explains every anomaly found
  in the time intelligence analysis

Category Revenue by Year:
- 2015: Bikes 100% of revenue
- 2016: Bikes 94.04%, Accessories 4.28%,
        Clothing 1.67%
- 2017: Bikes 92.20%, Accessories 5.52%,
        Clothing 2.28%
- Non-bike categories growing share each period
- Accessories on pace for $1M+ full year 2017

Bike Revenue Growth Independent of New Categories:
- Bike revenue grew from $6.4M (2015) to
  $8.77M (2016) -- 37% growth in bikes alone
- New categories were purely additive growth
- Core bike business was already accelerating
  before accessories launched

Accessories and Clothing Growth Rate:
- Accessories: $399K in H2 2016 vs $507K in H1 2017
  Annualised 2017 pace: ~$1.01M -- 153% YoY growth
- Clothing: $156K in H2 2016 vs $209K in H1 2017
  Annualised 2017 pace: ~$418K -- 168% YoY growth
- Both non-bike categories accelerating rapidly

Recontextualisation of Earlier Findings:
- High 2015 avg order value: all orders were bikes
- Unit volume explosion 2016: accessories launch
- Seasonal pattern change 2016: accessories have
  different seasonality than premium bikes
- Flat day of week pattern: consistent with
  online accessory purchasing behaviour
- Bottom 10 revenue products all accessories:
  only available for partial dataset period

Limitation: Cannot determine exact launch date
within July 2016 from available data. First
accessory sale recorded in July 2016 but exact
date within that month not isolated in this query.
--------------*/

/*--- SECTION 6 SUMMARY ---
The single most important finding in the entire
time intelligence analysis:

AdventureWorks was a pure bike business from
January 2015 through June 2016. It launched
Accessories and Clothing simultaneously in
July 2016, transforming from a single category
business into a multi-category retailer.

Every growth pattern, inflection point, and
anomaly observed in Sections 1 through 5
traces back to this one event.
--------------*/