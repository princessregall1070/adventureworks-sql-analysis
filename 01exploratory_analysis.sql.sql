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

SELECT 'Sales2015' AS AdventureWorks_Customers,
COUNT(*) AS CountRows
FROM AdventureWorks_Customers
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
SELECT 'Customers',
COUNT(*) AS CountOfRows
FROM AdventureWorks_Customers
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

-- Number of products per category
SELECT 
    ProductKey,
    COUNT(*) AS NumberOfProducts
FROM AdventureWorks_Products
GROUP BY ProductKey
ORDER BY NumberOfProducts DESC;

-- Products returned more than once (quality flag)
SELECT 
    ProductKey,
    COUNT(*) AS TimesReturned
FROM AdventureWorks_Returns
GROUP BY ProductKey
HAVING COUNT(*) > 1
ORDER BY TimesReturned DESC;

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

-- Find products that were never sold (dead stock check)
SELECT 
    p.ProductKey,
    p.ProductName
FROM AdventureWorks_Products AS p
LEFT JOIN AdventureWorks_Sales_2015 AS s
    ON p.ProductKey = s.ProductKey
WHERE s.ProductKey IS NULL;