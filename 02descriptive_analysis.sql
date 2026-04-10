/*
SELECT 'Sales2015' AS AdventureWorks_Sales_2015, 
COUNT(*) AS CountRow 
FROM AdventureWorks_Sales_2015
UNION ALL 
SELECT 'Sales2016' AS AdventureWorks_Sales_2016, 
COUNT(*) AS CountRow 
FROM AdventureWorks_Sales_2016
UNION ALL 
SELECT 'Sales2017' AS AdventureWorks_Sales_2017, 
COUNT(*) AS CountRow 
FROM AdventureWorks_Sales_2017
UNION ALL
SELECT 'Customers' AS AdventureWorks_Customers, 
COUNT(*) AS CountRow 
FROM AdventureWorks_Customers
UNION ALL 
SELECT 'Products' AS AdventureWorks_Products, 
COUNT(*) AS CountRow 
FROM AdventureWorks_Products
UNION ALL 
SELECT 'Returns' AS AdventureWorks_Returns, 
COUNT(*) AS CountRow 
FROM AdventureWorks_Returns
UNION ALL
SELECT 'Territories' AS AdventureWorks_Territories, 
COUNT(*) AS CountRow 
FROM AdventureWorks_Territories
UNION ALL
SELECT 'Categories' AS AdventureWorks_Product_Categories, 
COUNT(*) AS CountRow 
FROM AdventureWorks_Product_Categories
UNION ALL
SELECT 'Subcategories' AS AdventureWorks_Product_Subcategories, 
COUNT(*) AS CountRow 
FROM AdventureWorks_Product_Subcategories
UNION ALL
SELECT 'Calendar' AS AdventureWorks_Calendar, 
COUNT(*) AS CountRow 
FROM AdventureWorks_Calendar;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'AdventureWorks_Sales_2015'
ORDER BY ORDINAL_POSITION;
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'AdventureWorks_Sales_2016'
ORDER BY ORDINAL_POSITION;
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'AdventureWorks_Sales_2017'
ORDER BY ORDINAL_POSITION;
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'AdventureWorks_Products'
ORDER BY ORDINAL_POSITION;
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'AdventureWorks_Customers'
ORDER BY ORDINAL_POSITION;
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'AdventureWorks_Returns'
*/

/*============================================
   ADVENTUREWORKS DESCRIPTIVE ANALYSIS
   Analyst: Omolola Labiyi
   Date: April 2026
   Database: AdventureWorks
   Purpose: Summarize what happened across
   sales, products, customers and returns
=============================================*/

/*--------------------------------------------
   SECTION 1: CREATE ALL SALES VIEW
   Goal: Stack all 3 years into one table
   so every query below works across all years
--------------------------------------------*/
/*
-- Create view combining all three sales years
CREATE VIEW AllSales AS
SELECT OrderDate, StockDate, OrderNumber, ProductKey, 
       CustomerKey, TerritoryKey, OrderLineItem, OrderQuantity
FROM AdventureWorks_Sales_2015
UNION ALL
SELECT OrderDate, StockDate, OrderNumber, ProductKey, 
       CustomerKey, TerritoryKey, OrderLineItem, OrderQuantity
FROM AdventureWorks_Sales_2016
UNION ALL
SELECT OrderDate, StockDate, OrderNumber, ProductKey, 
       CustomerKey, TerritoryKey, OrderLineItem, OrderQuantity
FROM AdventureWorks_Sales_2017;

-- Confirm view created correctly
-- Should match 2630 + 23935 + 29481 = 56046 total rows
SELECT COUNT(*) AS TotalAllYears
FROM AllSales;
*/

/*--------------------------------------------
   SECTION 2: OVERALL REVENUE SUMMARY
   Goal: Understand total revenue and units
   sold across the entire dataset
   Note: No price column in sales tables --
   must JOIN to Products for ProductPrice
--------------------------------------------*/

-- Total units sold and revenue across all years
SELECT
    SUM(s.OrderQuantity) AS TotalUnitsSold,
    SUM(s.OrderQuantity * p.ProductPrice) AS TotalRevenue,
    SUM(s.OrderQuantity * p.ProductCost) AS TotalCost,
    SUM(s.OrderQuantity * p.ProductPrice) - 
    SUM(s.OrderQuantity * p.ProductCost) AS TotalProfit
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey;

-- Total revenue broken down by year
SELECT
    YEAR(s.OrderDate) AS SalesYear,
    SUM(s.OrderQuantity) AS TotalUnitsSold,
    SUM(s.OrderQuantity * p.ProductPrice) AS TotalRevenue,
    SUM(s.OrderQuantity * p.ProductPrice) -
    SUM(s.OrderQuantity * p.ProductCost) AS TotalProfit
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY YEAR(s.OrderDate)
ORDER BY SalesYear;

-- Total revenue broken down by quarter
SELECT
    YEAR(s.OrderDate) AS SalesYear,
    DATEPART(quarter, s.OrderDate) AS SalesQuarter,
    SUM(s.OrderQuantity * p.ProductPrice) AS TotalRevenue
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY YEAR(s.OrderDate), DATEPART(quarter, s.OrderDate)
ORDER BY SalesYear, SalesQuarter;

-- Total revenue broken down by month
SELECT
    YEAR(s.OrderDate) AS SalesYear,
    MONTH(s.OrderDate) AS SalesMonth,
    DATENAME(month, s.OrderDate) AS MonthName,
    SUM(s.OrderQuantity * p.ProductPrice) AS TotalRevenue
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY YEAR(s.OrderDate), MONTH(s.OrderDate), DATENAME(month, s.OrderDate)
ORDER BY SalesYear, SalesMonth;

/*--------------------------------------------
   SECTION 2 FINDINGS
   
   Overall:
   - Total revenue: $24.9M across 3 years
   - Total profit: $10.5M -- 42% profit margin
   
   By Year:
   - 2015: $6.4M revenue from only 2,630 orders
     High average order value -- premium products
   - 2016: $9.3M revenue -- volume increase drives growth
   - 2017: $9.2M revenue but only partial year (Jan-Jun)
     On pace to exceed 2016 if full year available
   
   Quarterly Trend:
   - Clear Q4 acceleration each year
   - 2017 Q2 is highest quarter on record at $5.1M
   - Strong momentum heading into second half of 2017
   
   Monthly Trend:
   - December consistently strong
   - 2017 showing month over month growth every month
--------------------------------------------*/
/*
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'AdventureWorks_Territories'
ORDER BY ORDINAL_POSITION;
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'AdventureWorks_Product_Categories'
ORDER BY ORDINAL_POSITION;
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'AdventureWorks_Product_Subcategories'
ORDER BY ORDINAL_POSITION;
*/
/*--------------------------------------------
   SECTION 3: PRODUCT PERFORMANCE
   Goal: Find best and worst performing
   products by revenue, profit and volume
--------------------------------------------*/

-- Top 10 products by total revenue
SELECT TOP 10
    p.ProductName,
    p.ProductPrice,
    SUM(s.OrderQuantity) AS TotalUnitsSold,
    SUM(s.OrderQuantity * p.ProductPrice) AS TotalRevenue,
    SUM(s.OrderQuantity * p.ProductPrice) -
    SUM(s.OrderQuantity * p.ProductCost) AS TotalProfit
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY p.ProductName, p.ProductPrice
ORDER BY TotalRevenue DESC;

-- Bottom 10 products by total revenue
SELECT TOP 10
    p.ProductName,
    p.ProductPrice,
    SUM(s.OrderQuantity) AS TotalUnitsSold,
    SUM(s.OrderQuantity * p.ProductPrice) AS TotalRevenue
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY p.ProductName, p.ProductPrice
ORDER BY TotalRevenue ASC;

-- Revenue and profit by product category
-- Requires joining through subcategories to categories
SELECT
    cat.CategoryName,
    SUM(s.OrderQuantity) AS TotalUnitsSold,
    SUM(s.OrderQuantity * p.ProductPrice) AS TotalRevenue,
    SUM(s.OrderQuantity * p.ProductPrice) -
    SUM(s.OrderQuantity * p.ProductCost) AS TotalProfit
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
LEFT JOIN AdventureWorks_Product_Subcategories AS sub
    ON p.ProductSubcategoryKey = sub.ProductSubcategoryKey
LEFT JOIN AdventureWorks_Product_Categories AS cat
    ON sub.ProductCategoryKey = cat.ProductCategoryKey
GROUP BY cat.CategoryName
ORDER BY TotalRevenue DESC;

-- Revenue by subcategory
SELECT
    sub.SubcategoryName,
    cat.CategoryName,
    SUM(s.OrderQuantity) AS TotalUnitsSold,
    SUM(s.OrderQuantity * p.ProductPrice) AS TotalRevenue
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
LEFT JOIN AdventureWorks_Product_Subcategories AS sub
    ON p.ProductSubcategoryKey = sub.ProductSubcategoryKey
LEFT JOIN AdventureWorks_Product_Categories AS cat
    ON sub.ProductCategoryKey = cat.ProductCategoryKey
GROUP BY sub.SubcategoryName, cat.CategoryName
ORDER BY TotalRevenue DESC;

/*--------------------------------------------
   SECTION 3 FINDINGS

   Top Products:
   - Mountain-200 dominates -- 6 variations
     in top 10, all priced around $2,049
   - Road-250 takes spots 7-9 at $2,181 each
   - Road-150 Red is most expensive at $3,578
     but lower volume limits total revenue

   Bottom Products:
   - Racing Socks lowest revenue at $4,575
   - Patch Kit highest volume (5,898 units)
     but lowest price at $2.29
   - Accessories dominate bottom 10 entirely

   Category Breakdown:
   - Bikes = 94.9% of total revenue ($23.6M)
     from only 16.5% of units sold
   - Accessories = 68.7% of units sold
     but only 3.6% of revenue ($906K)
   - Clothing = 15% of units, 1.5% of revenue
   - Business is entirely dependent on bike sales

   Subcategory Breakdown:
   - Road Bikes: $11.3M -- largest subcategory
   - Mountain Bikes: $8.6M -- second largest
   - Touring Bikes: $3.8M -- distant third
   - All other subcategories combined under $2M
--------------------------------------------*/

/*--------------------------------------------
   SECTION 4: CUSTOMER ANALYSIS
   Goal: Understand who is buying and
   how much they are spending
--------------------------------------------*/

-- Total revenue per customer ranked highest to lowest
SELECT TOP 20
    c.CustomerKey,
    c.FirstName,
    c.LastName,
    COUNT(DISTINCT s.OrderNumber) AS TotalOrders,
    SUM(s.OrderQuantity) AS TotalUnitsBought,
    SUM(s.OrderQuantity * p.ProductPrice) AS TotalSpend
FROM AllSales AS s
LEFT JOIN AdventureWorks_Customers AS c
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY c.CustomerKey, c.FirstName, c.LastName
ORDER BY TotalSpend DESC;

-- Average spend per customer
SELECT
    AVG(CustomerSpend) AS AvgCustomerSpend,
    MIN(CustomerSpend) AS LowestSpend,
    MAX(CustomerSpend) AS HighestSpend
FROM (
    SELECT
        s.CustomerKey,
        SUM(s.OrderQuantity * p.ProductPrice) AS CustomerSpend
    FROM AllSales AS s
    LEFT JOIN AdventureWorks_Products AS p
        ON s.ProductKey = p.ProductKey
    GROUP BY s.CustomerKey
) AS CustomerTotals;

-- Revenue breakdown by customer occupation
SELECT
    c.Occupation,
    COUNT(DISTINCT c.CustomerKey) AS NumberOfCustomers,
    SUM(s.OrderQuantity * p.ProductPrice) AS TotalRevenue,
    AVG(s.OrderQuantity * p.ProductPrice) AS AvgRevenuePerSale
FROM AllSales AS s
LEFT JOIN AdventureWorks_Customers AS c
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY c.Occupation
ORDER BY TotalRevenue DESC;

-- Revenue breakdown by customer gender
SELECT
    c.Gender,
    COUNT(DISTINCT c.CustomerKey) AS NumberOfCustomers,
    SUM(s.OrderQuantity * p.ProductPrice) AS TotalRevenue
FROM AllSales AS s
LEFT JOIN AdventureWorks_Customers AS c
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY c.Gender
ORDER BY TotalRevenue DESC;

-- Revenue breakdown by customer income level
SELECT
    c.AnnualIncome,
    COUNT(DISTINCT c.CustomerKey) AS NumberOfCustomers,
    SUM(s.OrderQuantity * p.ProductPrice) AS TotalRevenue
FROM AllSales AS s
LEFT JOIN AdventureWorks_Customers AS c
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
GROUP BY c.AnnualIncome
ORDER BY c.AnnualIncome DESC;

/*--------------------------------------------
   SECTION 4 FINDINGS

   Top Customers:
   - Maurice Shan highest spender at $12,407
     across only 6 orders -- buying premium bikes
   - Lisa Cai 33 units across 7 orders --
     mix of bikes and accessories
   - Top 20 all spent between $9,700 and $12,400
   - Note: Names still in ALL CAPS -- 
     apply ProperCase fix before final presentation

   Average Spend:
   - Avg customer spend: $1,430
   - Lowest: $2.29 -- single Patch Kit purchase
   - Highest: $12,407 -- Maurice Shan
   - Wide spread indicates very mixed customer base

   By Occupation:
   - Professionals largest group (5,219) AND
     highest avg spend per sale ($476)
   - Management second highest avg at $472
   - Manual workers lowest avg spend at $378
   - Clear correlation: higher occupation = higher spend

   By Gender:
   - Near perfect 50/50 split male vs female
   - Female customers slightly higher total revenue
     ($12.5M vs $12.2M) despite fewer customers
   - 123 records with no gender -- data quality flag

   By Income:
   - Core customer is middle income $40K-$70K
   - $70K bracket generates most revenue at $3.78M
   - High earners ($150K-$170K) surprisingly low revenue
   - Business serves middle income market, not luxury
--------------------------------------------*/

/*--------------------------------------------
   SECTION 5: TERRITORY PERFORMANCE
   Goal: Understand which regions drive
   the most revenue and volume
--------------------------------------------*/

-- Revenue by territory
SELECT
    t.SalesTerritoryKey,
    t.Region,
    t.Country,
    t.Continent,
    SUM(s.OrderQuantity) AS TotalUnitsSold,
    SUM(s.OrderQuantity * p.ProductPrice) AS TotalRevenue
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
LEFT JOIN AdventureWorks_Territories AS t
    ON s.TerritoryKey = t.SalesTerritoryKey
GROUP BY t.SalesTerritoryKey, t.Region, t.Country, t.Continent
ORDER BY TotalRevenue DESC;

-- Revenue by continent
SELECT
    t.Continent,
    SUM(s.OrderQuantity * p.ProductPrice) AS TotalRevenue,
    COUNT(DISTINCT s.CustomerKey) AS UniqueCustomers
FROM AllSales AS s
LEFT JOIN AdventureWorks_Products AS p
    ON s.ProductKey = p.ProductKey
LEFT JOIN AdventureWorks_Territories AS t
    ON s.TerritoryKey = t.SalesTerritoryKey
GROUP BY t.Continent
ORDER BY TotalRevenue DESC;

-- Fix ALL CAPS names in Customers table
UPDATE AdventureWorks_Customers
SET
    FirstName = ProperCase(FirstName),
    LastName = ProperCase(LastName),
    Prefix = ProperCase(Prefix);
/*
USE AdventureWorks;
GO

CREATE FUNCTION dbo.ProperCase (@Text NVARCHAR(255))
RETURNS NVARCHAR(255)
AS
BEGIN
    DECLARE @Result NVARCHAR(255) = LOWER(@Text)
    DECLARE @i INT = 1

    WHILE @i <= LEN(@Result)
    BEGIN
        IF @i = 1 OR SUBSTRING(@Result, @i - 1, 1) = ' '
            SET @Result = STUFF(@Result, @i, 1, UPPER(SUBSTRING(@Result, @i, 1)))
        SET @i = @i + 1
    END

    RETURN @Result
END;
*/
SELECT name, type_desc
FROM sys.objects
WHERE name = 'ProperCase';

USE AdventureWorks;
GO

-- Fix ALL CAPS names in Customers table
UPDATE AdventureWorks_Customers
SET
    FirstName = dbo.ProperCase(FirstName),
    LastName = dbo.ProperCase(LastName),
    Prefix = dbo.ProperCase(Prefix);
--Test
SELECT TOP 10 Prefix, FirstName, LastName
FROM AdventureWorks_Customers;
/*--------------------------------------------
   SECTION 6: RETURNS ANALYSIS
   Goal: Understand what is being returned
   and identify any problem products
--------------------------------------------*/

-- Total returns summary
SELECT
    SUM(ReturnQuantity) AS TotalUnitsReturned,
    COUNT(*) AS TotalReturnTransactions,
    COUNT(DISTINCT ProductKey) AS UniqueProductsReturned
FROM AdventureWorks_Returns;

-- Return rate by product
-- Return rate = units returned divided by units sold
SELECT TOP 20
    p.ProductName,
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
ORDER BY ReturnRatePct DESC;

-- Returns by territory
SELECT
    t.Region,
    t.Country,
    SUM(r.ReturnQuantity) AS TotalReturned,
    COUNT(*) AS ReturnTransactions
FROM AdventureWorks_Returns AS r
LEFT JOIN AdventureWorks_Territories AS t
    ON r.TerritoryKey = t.SalesTerritoryKey
GROUP BY t.Region, t.Country
ORDER BY TotalReturned DESC;

-- Returns by year
SELECT
    YEAR(r.ReturnDate) AS ReturnYear,
    SUM(r.ReturnQuantity) AS TotalReturned,
    COUNT(*) AS ReturnTransactions
FROM AdventureWorks_Returns AS r
GROUP BY YEAR(r.ReturnDate)
ORDER BY ReturnYear;

/*--------------------------------------------
   SECTION 6 FINDINGS

   Overall Returns:
   - 1,828 units returned from 84,174 sold
   - Overall return rate: 2.17% -- healthy
   - 124 unique products returned out of 293
   - Note: Original query had JOIN issue causing
     100%+ return rates -- fixed using subqueries

   Problem Products:
   - Road-650 Red highest return rate at 11.76%
     Multiple sizes in top 20 -- model quality issue
   - Mountain-100 appears multiple times -- 
     consistent sizing or quality problem
   - Touring-3000 appears multiple times --
     similar pattern to Mountain-100
   - Classic Vest and Womens Mountain Shorts
     both above 5% -- clothing sizing issues likely

   By Territory:
   - Australia most raw returns (404) but
     proportional to sales volume
   - All territories between 2.04% and 2.37%
   - Returns are NOT a territory specific problem
   - France very slightly elevated at 2.37%
   - Southeast US only 1 return -- confirms
     territory is essentially inactive

   By Year:
   - 2015: 86 returns (low sales volume year)
   - 2016: 770 returns
   - 2017: 972 returns Jan-Jun only --
     on pace to significantly exceed 2016
   - Growth in returns proportional to sales growth
   - No worsening return rate trend detected
--------------------------------------------*/