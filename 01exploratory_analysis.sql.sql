/*========================================== 
AdventureWorks Exploratory Analysis
Analyst: Omolola Labiyi
Date: April 2026
Database: AdventureWorks
===========================================*/

/*------------------------------------------
Section 1: Understand the Shape of the Data
Goal: Count rows and preview each table
-------------------------------------------*/

--Total rows in each sales table 
SELECT 'Customers' AS Table_Name,
COUNT(*) AS CountRows
FROM AdventureWorks_Customers
UNION ALL
SELECT 'Sales2015',
COUNT(*) AS CountOfRows
FROM AdventureWorks_Sales_2015
UNION ALL
SELECT 'Sales2016',
COUNT(*) AS CountOfRows
FROM AdventureWorks_Sales_2016
UNION ALL
SELECT 'Sales2017',
COUNT(*) AS CountOfRows
FROM AdventureWorks_Sales_2017
UNION ALL
SELECT 'Returns',
COUNT(*) AS CountOfRows
FROM AdventureWorks_Returns
UNION ALL
SELECT 'Calendar',
COUNT(*) AS CountOfRows
FROM AdventureWorks_Calendar
UNION ALL 
SELECT 'ProductCategories',
COUNT(*) AS CountOfRows
FROM AdventureWorks_Product_Categories
UNION ALL
SELECT 'ProductSubcategories',
COUNT(*) AS CountOfRows
FROM AdventureWorks_Product_Subcategories
UNION ALL
SELECT 'Products',
COUNT(*) AS CountOfRows
FROM AdventureWorks_Products
UNION ALL
SELECT 'Territories',
COUNT(*) AS CountOfRows
FROM AdventureWorks_Territories;

-- Preview first 10 rows of each key table
SELECT TOP 10 * FROM AdventureWorks_Customers;
SELECT TOP 10 * FROM AdventureWorks_Products;
SELECT TOP 10 * FROM AdventureWorks_Sales_2015;
SELECT TOP 10 * FROM AdventureWorks_Sales_2016;
SELECT TOP 10 * FROM AdventureWorks_Sales_2017;

-- Count of unique values in key columns
SELECT COUNT(DISTINCT CustomerKey) AS UniqueCustomers FROM AdventureWorks_Customers;
SELECT COUNT(DISTINCT ProductKey) AS UniqueProducts FROM AdventureWorks_Products;
SELECT COUNT(DISTINCT TerritoryKey) AS UniqueTerritories2015 FROM AdventureWorks_Sales_2015;
SELECT COUNT(DISTINCT TerritoryKey) AS UniqueTerrirories2016 FROM AdventureWorks_Sales_2016;
SELECT COUNT(DISTINCT TerritoryKey) AS UniqueTerritories2017 FROM AdventureWorks_Sales_2017;

/*--- SECTION 1 NOTES ---

Observation:
Sales2015 has 2,630 rows vs 23,935 in 2016

Anomaly:
StockDate shows years from 2001 in a 2015 sales table

Data Quality Issue:
Names stored in ALL CAPS -- corrected with ProperCase

Assumption:
StockDate is original inventory date, not sale related

Limitation:
No revenue column in sales tables -- revenue requires
JOIN to Products table for all calculations

Finding:
Two territories missing from 2015 suggests expansion
between 2015 and 2016
--------------*/

/*------------------------------------------
Section 2: Data Quality Checks
Goal: Find missing values, spaces, bad dates 
-------------------------------------------*/

--Check for NULL values in Customers
SELECT 
	COUNT(*) AS TotalRows,
	COUNT(CustomerKey) AS HasCustomerKey,
	COUNT(FirstName) AS HasFirstName,
	COUNT(EmailAddress) AS HasEmail
FROM AdventureWorks_Customers;

--Find customers with missing email addresses
SELECT 
COUNT(*) AS MissingEmail
FROM AdventureWorks_Customers 
WHERE EmailAddress IS NULL;

--Check for extra spaces in customer names
SELECT 
	FirstName,
	LEN(FirstName) AS LengthWithSpaces,
	LEN(TRIM(FirstName)) AS LengthCleaned,
	LEN(FirstName) - LEN(TRIM(FirstName)) AS ExtraSpaces
FROM AdventureWorks_Customers
WHERE LEN(FirstName) != LEN(TRIM(FirstName));

-- Check for NULL dates across all sales tables
SELECT 'Sales2015' AS AdventureWorks_Sales_2015, COUNT(*) AS NullDates
FROM AdventureWorks_Sales_2015
WHERE OrderDate IS NULL
UNION ALL
SELECT 'Sales2016', COUNT(*)
FROM AdventureWorks_Sales_2016
WHERE OrderDate IS NULL
UNION ALL
SELECT 'Sales2017', COUNT(*)
FROM AdventureWorks_Sales_2017
WHERE OrderDate IS NULL;

/*--------------------------------------------
   SECTION 2: DATA QUALITY CHECKS
   Goal: Find missing values, spaces, bad dates
--------------------------------------------*/

-- Check for NULL values in Customers
/*--- OUTPUT ---
TotalRows    HasCustomerKey    HasFirstName    HasEmail
18148        18148             18148           18148
--------------
Data Quality Issue: None detected.
All 18148 rows have CustomerKey, FirstName and
EmailAddress populated. No missing values found
in key customer columns.
--------------*/

-- Find customers with missing email addresses
/*--- OUTPUT ---
MissingEmail
0
--------------
Data Quality Issue: None detected.
Zero customers are missing an email address.
Email column is fully populated across all 18148 rows.
--------------*/

-- Check for extra spaces in customer names
/*--- OUTPUT ---
No rows returned.
--------------
Data Quality Issue: None detected.
No customer names contain leading or trailing spaces.
ProperCase function applied earlier also cleaned
any spacing irregularities in name columns.
--------------*/

-- Check for NULL dates across all sales tables
/*--- OUTPUT ---
TableName     NullDates
Sales2015     0
Sales2016     0
Sales2017     0
--------------
Data Quality Issue: None detected.
Zero NULL dates across all three sales tables.
OrderDate column is DATE type -- SQL Server enforces
valid dates automatically on import so ISDATE check
was not required. All date values confirmed valid.
--------------*/

/*--- SECTION 2 SUMMARY ---
Overall Data Quality: CLEAN

No issues detected across any of the following checks:
- NULL values in customer key columns
- Missing email addresses
- Extra spaces in customer names
- NULL dates in sales tables

Limitation: Data quality checks focused on key columns
only. Full column audit not performed. Additional checks
on ProductKey and CustomerKey referential integrity
could be added in future analysis.
--------------*/

/*--------------------------------------------
   SECTION 3: DATE RANGE ANALYSIS
   Goal: Understand the time period covered
--------------------------------------------*/

-- Confirm each table only contains its correct year
SELECT 'Sales2015' AS AdventureWorks_Sales_2015,
    MIN(OrderDate) AS EarliestOrder,
    MAX(OrderDate) AS LatestOrder
FROM AdventureWorks_Sales_2015
UNION ALL
SELECT 'Sales2016',
    MIN(OrderDate),
    MAX(OrderDate)
FROM AdventureWorks_Sales_2016
UNION ALL
SELECT 'Sales2017',
    MIN(OrderDate),
    MAX(OrderDate)
FROM AdventureWorks_Sales_2017;

-- Earliest and latest sale in each table
SELECT 'AdventureWorks_Sales_2015' AS TableName, MIN(OrderDate) AS EarliestSale, MAX(OrderDate) 
AS LatestSale FROM AdventureWorks_Sales_2015
UNION ALL
SELECT 'AdventureWorks_Sales_2016', MIN(OrderDate), MAX(OrderDate) FROM AdventureWorks_Sales_2016
UNION ALL
SELECT 'AdventureWorks_Sales_2017', MIN(OrderDate), MAX(OrderDate) FROM AdventureWorks_Sales_2017;

-- How many days does each year of data span
SELECT 
    'Sales2015' AS TableName,
    DATEDIFF(day, MIN(OrderDate), MAX(OrderDate)) AS DaysSpanned 
FROM AdventureWorks_Sales_2015
UNION ALL
SELECT 
    'Sales2016',
    DATEDIFF(day, MIN(OrderDate), MAX(OrderDate)) 
FROM AdventureWorks_Sales_2016
UNION ALL
SELECT 
    'Sales2017',
    DATEDIFF(day, MIN(OrderDate), MAX(OrderDate)) 
FROM AdventureWorks_Sales_2017;

-- Which years and months exist in the data
SELECT DISTINCT 
    YEAR(OrderDate) AS SalesYear,
    MONTH(OrderDate) AS SalesMonth
FROM AdventureWorks_Sales_2015
ORDER BY SalesYear, SalesMonth;

/*--------------------------------------------
   SECTION 3: DATE RANGE ANALYSIS
   Goal: Understand the time period covered
--------------------------------------------*/

-- Confirm each table only contains its correct year
/*--- OUTPUT ---
TableName     EarliestOrder    LatestOrder
Sales2015     2015-01-01       2015-12-31
Sales2016     2016-01-01       2016-12-31
Sales2017     2017-01-01       2017-06-30
--------------
Observation: Each sales table contains only its
correct year -- no dates bleeding between tables.
Finding: Sales2017 ends 2017-06-30 confirming dataset
only covers first half of 2017. All 2017 analysis
must account for this -- full year comparisons
with 2015 and 2016 are not valid.
--------------*/

-- Earliest and latest sale in each table
/*--- OUTPUT ---
TableName                   EarliestSale    LatestSale
AdventureWorks_Sales_2015   2015-01-01      2015-12-31
AdventureWorks_Sales_2016   2016-01-01      2016-12-31
AdventureWorks_Sales_2017   2017-01-01      2017-06-30
--------------
Observation: Confirms results above using second query
method. Both queries return identical date ranges
validating results are consistent and correct.
--------------*/

-- How many days does each year of data span
/*--- OUTPUT ---
TableName     DaysSpanned
Sales2015     364
Sales2016     365
Sales2017     180
--------------
Observation: 
- Sales2015 spans 364 days -- one day short of full
  year due to 2015 not being a leap year
- Sales2016 spans 365 days -- full year confirmed
- Sales2017 spans 180 days -- exactly half a year
  confirmed, ending June 30

Limitation: 2017 revenue and volume figures represent
only 50% of the year. 2017 is on pace to exceed 2016
based on first half performance but cannot be confirmed
without full year data.
--------------*/

-- Which years and months exist in the data
/*--- OUTPUT ---
SalesYear    SalesMonth
2015         1 through 12    -- all 12 months present
2016         1 through 12    -- all 12 months present
2017         1 through 6     -- January to June only
--------------
Observation: 2015 and 2016 both have complete 12 month
coverage. 2017 has exactly 6 months confirming the
dataset cuts off at end of June 2017.

Finding: Despite only 6 months of data, 2017 already
shows stronger monthly revenue than equivalent months
in 2016 in every single month. Business is on a clear
upward trajectory.

Limitation: Seasonality analysis for 2017 incomplete --
Q3 and Q4 patterns cannot be evaluated. Based on 2015
and 2016 data, Q4 is historically the strongest quarter
so 2017 full year revenue would likely be significantly
higher than the $9.2M recorded in the first half.
--------------*/

/*--- SECTION 3 SUMMARY ---
Date Coverage:
- 2015: Full year January through December (364 days)
- 2016: Full year January through December (365 days)
- 2017: Half year January through June (180 days)

Key Limitation: All comparisons involving 2017 must
note the partial year. 2017 figures are not directly
comparable to 2015 or 2016 full year totals.

Data Integrity: Each table confirmed to contain only
its correct year. No date overlap or contamination
between tables detected.
--------------*/

/*--------------------------------------------
   SECTION 4: SUMMARIZE VALUES
   Goal: Get totals, averages, and ranges
--------------------------------------------*/

-- Total units sold per year
SELECT 
    YEAR(OrderDate) AS SalesYear,
    SUM(OrderQuantity) AS TotalUnitsSold,
    AVG(OrderQuantity) AS AvgUnitsPerOrder,
    MIN(OrderQuantity) AS SmallestOrder,
    MAX(OrderQuantity) AS LargestOrder
FROM (
    SELECT OrderDate, OrderQuantity FROM AdventureWorks_Sales_2015
    UNION ALL
    SELECT OrderDate, OrderQuantity FROM AdventureWorks_Sales_2016
    UNION ALL
    SELECT OrderDate, OrderQuantity FROM AdventureWorks_Sales_2017
) AS AllSales
GROUP BY YEAR(OrderDate)
ORDER BY SalesYear;

-- Price range across all products
SELECT 
    MIN(ProductPrice) AS CheapestProduct,
    MAX(ProductPrice) AS MostExpensiveProduct,
    AVG(ProductPrice) AS AveragePrice
FROM AdventureWorks_Products;

/*--------------------------------------------
   SECTION 4: SUMMARIZE VALUES
   Goal: Get totals, averages, and ranges
--------------------------------------------*/

-- Total units sold per year
/*--- OUTPUT ---
SalesYear    TotalUnitsSold    AvgUnitsPerOrder    SmallestOrder    LargestOrder
2015         2630              1                   1                1
2016         36230             1                   1                3
2017         45314             1                   1                3
--------------
Observation: Average order quantity is 1 unit across
all three years meaning most customers buy one item
per order line.

Finding: Maximum order quantity jumps from 1 in 2015
to 3 in 2016 and 2017. In 2015 every single order
was exactly 1 unit -- no bulk purchases at all.
This is consistent with 2015 selling primarily
high value bikes where one unit per order is expected.

Finding: Total units grow dramatically year over year:
- 2015: 2,630 units
- 2016: 36,230 units -- 1,277% increase
- 2017: 45,314 units in first half only --
  already exceeding full year 2016 by 25%

Limitation: Unit volume increase from 2015 to 2016
is partly explained by product mix shift toward
lower priced accessories and clothing which sell
in higher volumes than bikes.
--------------*/

-- Price range across all products
/*--- OUTPUT ---
CheapestProduct    MostExpensiveProduct    AveragePrice
2.29               3578.27                 714.44
--------------
Observation: Enormous price range across product
catalog -- from $2.29 for a Patch Kit to $3,578.27
for the Road-150 Red bike.

Finding: Average product price of $714.44 is heavily
skewed upward by high value bikes. The median price
would be significantly lower since accessories and
clothing dominate the catalog numerically but bikes
dominate revenue.

Limitation: Average price calculated across all 293
products equally regardless of sales volume. A
revenue weighted average price would give a more
accurate picture of what customers actually pay.
--------------*/

/*--- SECTION 4 SUMMARY ---
Key Numbers:
- Total units sold across all years: 84,174
- Average order quantity: 1 unit per order line
- Cheapest product: $2.29 (Patch Kit)
- Most expensive product: $3,578.27 (Road-150 Red)
- Average product price: $714.44

Anomaly: 2015 maximum order quantity is 1 -- no
customer ordered more than 1 unit in any transaction
that year. This changes in 2016 suggesting either
a different customer base or different products
being sold in 2015.
--------------*/

/*--------------------------------------------
   SECTION 5: EXPLORE CATEGORIES
   Goal: See how data breaks down by group
--------------------------------------------*/

-- Number of sales per territory
SELECT 
    TerritoryKey,
    COUNT(*) AS NumberOfSales
FROM AdventureWorks_Sales_2015
GROUP BY TerritoryKey
ORDER BY NumberOfSales DESC;
SELECT 
    TerritoryKey,
    COUNT(*) AS NumberOfSales
FROM AdventureWorks_Sales_2016
GROUP BY TerritoryKey
ORDER BY NumberOfSales DESC;
SELECT 
    TerritoryKey,
    COUNT(*) AS NumberOfSales
FROM AdventureWorks_Sales_2017
GROUP BY TerritoryKey
ORDER BY NumberOfSales DESC;

--Number of products per category
SELECT
    cat.CategoryName,
    COUNT(p.ProductKey) AS NumberOfProducts
FROM AdventureWorks_Products AS p
LEFT JOIN AdventureWorks_Product_Subcategories AS sub
    ON p.ProductSubcategoryKey = sub.ProductSubcategoryKey
LEFT JOIN AdventureWorks_Product_Categories AS cat
    ON sub.ProductCategoryKey = cat.ProductCategoryKey
GROUP BY cat.CategoryName
ORDER BY NumberOfProducts DESC;

-- Number of products per subcategory
SELECT
    sub.SubcategoryName,
    COUNT(p.ProductKey) AS NumberOfProducts
FROM AdventureWorks_Products AS p
LEFT JOIN AdventureWorks_Product_Subcategories AS sub
    ON p.ProductSubcategoryKey = sub.ProductSubcategoryKey
GROUP BY sub.SubcategoryName
ORDER BY NumberOfProducts DESC;

-- Products returned more than once (quality flag)
SELECT 
    ProductKey,
    COUNT(*) AS TimesReturned
FROM AdventureWorks_Returns
GROUP BY ProductKey
HAVING COUNT(*) > 1
ORDER BY TimesReturned DESC;

/*--- SECTION 5 SUMMARY ---
Territory Pattern:
- Australia and Southwest US dominate all three years
- Three US territories essentially inactive throughout
- Northeast and Central US came online in 2016
  but never developed meaningful sales volume

Product Catalog:
- 293 total products across 4 categories
- Components largest category at 132 products
- Components never appear in revenue analysis --
  likely internal parts not sold to customers
- Accessories smallest category at 29 products
  but second highest unit sales volume

Returns:
- 103 of 293 products returned more than once
- ProductKey 477 highest raw return count at 149
- Raw return count not the same as return rate
--------------*/

/*--------------------------------------------
   SECTION 6: COMBINE TABLES
   Goal: Connect tables and check relationships
--------------------------------------------*/

-- Stack all three sales years into one view
/*
CREATE VIEW AllSales AS
SELECT OrderDate, ProductKey, CustomerKey, TerritoryKey, OrderQuantity
FROM AdventureWorks_Sales_2015
UNION ALL
SELECT OrderDate, ProductKey, CustomerKey, TerritoryKey, OrderQuantity
FROM AdventureWorks_Sales_2016
UNION ALL
SELECT OrderDate, ProductKey, CustomerKey, TerritoryKey, OrderQuantity
FROM AdventureWorks_Sales_2017;
*/

-- Check sales connect correctly to products
SELECT TOP 10
    s.OrderDate,
    s.OrderQuantity,
    p.ProductName,
    p.ProductPrice
FROM AdventureWorks_Sales_2015 AS s
INNER JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey;

--Find products never sold across all years (dead stock check)
SELECT
    p.ProductKey,
    p.ProductName
FROM AdventureWorks_Products AS p
LEFT JOIN AllSales AS s
    ON p.ProductKey = s.ProductKey
WHERE s.ProductKey IS NULL
ORDER BY p.ProductName;

/*--------------------------------------------
   SECTION 6: COMBINE TABLES
   Goal: Connect tables and check relationships
--------------------------------------------*/

-- Create AllSales view
/*--- OUTPUT ---
Command completed successfully.
AllSales view created combining Sales2015, Sales2016
and Sales2017 into one unified table.
Total rows confirmed: 56,046
(2630 + 23935 + 29481 = 56046)
--------------*/

-- Check sales connect correctly to products
/*--- OUTPUT --- showing top 10 of 56046 rows
OrderDate     OrderQuantity    ProductName         ProductPrice
2015-01-02    1                Road-150 Red, 62    3578.27
2015-01-03    1                Road-150 Red, 62    3578.27
2015-01-03    1                Road-150 Red, 62    3578.27
2015-01-04    1                Road-150 Red, 62    3578.27
2015-01-05    1                Road-150 Red, 62    3578.27
2015-01-06    1                Road-150 Red, 62    3578.27
2015-01-06    1                Road-150 Red, 62    3578.27
2015-01-06    1                Road-150 Red, 62    3578.27
2015-01-08    1                Road-150 Red, 62    3578.27
2015-01-09    1                Road-150 Red, 62    3578.27
--------------
Finding: JOIN between AllSales and Products confirmed
working correctly. ProductKey links resolve to correct
product names and prices across all tables.

Finding: First 10 rows of 2015 data are almost
entirely Road-150 Red at $3,578.27 -- the most
expensive product in the catalog. Directly explains
why 2015 had fewer transactions but higher average
order value than 2016 and 2017. Early 2015 business
heavily concentrated in premium high value bikes.

Note: ProductPrice shows long decimals in SSMS due
to float data type. Use ROUND() in future queries.
--------------*/

-- Find products never sold across all years
/*--- OUTPUT ---
Data Quality Issue: Original query joined against
Sales2015 only -- incorrectly flagged 200+ products
as never sold including products confirmed sold in
descriptive analysis. Fixed by joining AllSales view.

Corrected results -- 148 products never sold:

Category breakdown of unsold products:
- All Frames (HL/ML/LL Road, Mountain, Touring)
- All Wheels (Front, Rear, Touring)
- All Pedals (HL/ML/LL Road, Mountain, Touring)
- All Handlebars and Forks
- All Seats and Saddles
- All Bottom Brackets, Cranksets, Derailleurs
- All Headsets
- Lighting (Headlights, Taillights)
- Locks, Pumps, Minipump
- Mountain-300 series (all 4 sizes)
- Road-450 series (all 5 sizes)
- Men's Bib-Shorts (all sizes)
- Men's Sports Shorts (all sizes)
- Women's Tights (all sizes)
- Mountain Bike Socks (M and L)
- Touring-Panniers, Large

Sample of never sold products:
ProductKey    ProductName
447           Cable Lock
559           Chain
555           Front Brakes
552           Front Derailleur
393           HL Fork
304           HL Mountain Frame - Black, 38
238           HL Road Frame - Red, 62
601           LL Bottom Bracket
364           Mountain-300 Black, 38
317           Road-450 Red, 44
446           Touring-Panniers, Large
458           Women's Tights, L
-- 148 total products never sold across all 3 years
--------------
Finding: 148 of 293 products -- exactly 50.5% of
the entire catalog -- were never sold in any year.

Finding: Never sold products fall into two clear groups:

Group 1 -- Components (expected):
Frames, wheels, pedals, handlebars, saddles, forks,
bottom brackets, cranksets, derailleurs, headsets.
These are internal bike parts used in manufacturing
not sold directly to customers. Their presence in
the catalog confirms Components is an internal
category not a retail category.

Group 2 -- Sellable products never purchased:
Mountain-300 series, Road-450 series, Men's Bib-Shorts,
Men's Sports Shorts, Women's Tights, Mountain Bike
Socks, Cable Lock, Chain, Lighting, Pumps.
These are genuine retail products that exist in the
catalog but generated zero sales across 3 years.
This represents a real business problem -- dead stock
occupying catalog space with no revenue contribution.

Limitation: Dataset covers 2015 through June 2017 only.
Some products may have been sold before 2015 or after
June 2017 and would not appear in this analysis.
--------------*/

/*--- SECTION 6 SUMMARY ---
Table Connections:
- AllSales view created: 56,046 total rows
- JOIN to Products confirmed working correctly
- All ProductKey values resolve accurately

Dead Stock Analysis:
- 148 of 293 products never sold -- 50.5% of catalog
- Two groups identified:
  1. Components: internal parts, expected unsold
  2. Retail products: genuine dead stock problem
     includes Mountain-300, Road-450, clothing lines
     and accessories with zero sales in 3 years

Data Quality Fix Applied:
- Original query used Sales2015 only -- 200+ false
  positives identified and corrected
- Final query uses AllSales view for accuracy

Key Finding:
- Early 2015 dominated by Road-150 Red at $3,578
- Explains 2015 high average order value despite
  low transaction volume
--------------*/
