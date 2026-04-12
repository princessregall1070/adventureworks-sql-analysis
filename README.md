# adventureworks-sql-analysis

# AdventureWorks Sales Analysis

A complete SQL Server analysis of the AdventureWorks dataset covering
exploratory analysis, descriptive analysis, and time intelligence.

## Tools Used
- SQL Server (SSMS)
- Power BI

## Dataset
AdventureWorks - 10 tables including 3 years of sales data (2015-2017),
customers, products, returns, territories, and a calendar table.

## Project Status
Complete

## Analysis Files

| File | Description | Status |
|---|---|---|
| [01_exploratory_analysis.sql](01exploratory_analysis.sql.sql) | Row counts, data quality checks, date ranges, dead stock | Complete | 
| [02_descriptive_analysis.sql](./02descriptive_analysis.sql) | Revenue summaries, top products, customers, territories, returns | Complete |
| [03_time_intelligence.sql](03time_intelligence.sql)  | Yearly, quarterly, monthly trends, seasonality, category growth |  Complete |
| [04_customer_analysis.sql](04customer_analysis.sql) | Customer growth, retention, RFM segmentation, demographics, lifetime value | Complete |
| [05_returns_analysis.sql](05_returns_analysis.sql) | Return rates, product issues, territory patterns, revenue impact, trends | Complete |

- ## Key Findings

### Data Overview
- 10 tables covering 3 years of sales (2015 through June 2017)
- 56,046 total transactions across 18,148 customers and 293 products
- 2017 data ends June 30 -- all 2017 figures represent first half only
- 148 of 293 products (50.5% of catalog) never sold in any year
- Components category (132 products) confirmed as internal parts not sold to customers

### Revenue
- Total revenue across all 3 years: $24.9M with a 42% profit margin
- 2015: $6.4M from only 2,630 transactions -- high average order value
- 2016: $9.3M -- dramatic volume increase as product mix shifted
- 2017: $9.2M in first half only -- on pace to significantly exceed 2016
- Clear Q4 acceleration pattern each year -- Q4 2016 was $3.8M alone
- 2017 Q2 is highest single quarter on record at $5.1M

### Products
- Bikes drive 94.9% of total revenue ($23.6M) from only 16.5% of units sold
- Accessories represent 68.7% of units sold but only 3.6% of revenue
- Mountain-200 and Road-250 dominate top 10 products by revenue
- Road-150 Red is most expensive product at $3,578 -- dominated early 2015 sales
- Bottom 10 products all accessories -- Racing Socks lowest at $4,575 total revenue
- Mountain-300 and Road-450 product lines never sold in any year -- dead stock

### Customers
- 18,148 total customers -- average spend $1,430 per customer
- Professionals are largest segment (5,219 customers) and highest avg spend ($476 per sale)
- Core customer is middle income $40K-$70K -- not a luxury market
- $70K income bracket generates most revenue at $3.78M
- Near perfect gender split -- female customers slightly higher total revenue ($12.5M vs $12.2M)
- Lowest single customer spend: $2.29 -- one Patch Kit purchase

### Territories
- Australia is single biggest territory at $7.4M -- larger than any individual US region
- Southwest US strongest domestic region at $4.8M
- Three US territories essentially inactive across all 3 years:
  - Southeast US: $11,585 total revenue
  - Northeast US: $6,401 total revenue  
  - Central US: $3,143 total revenue
- Pacific customers spend $2,131 per customer vs $1,111 for North America
- Pacific customers are 92% more valuable individually than North American customers

### Returns
- Overall return rate: 2.17% -- healthy for retail
- Road-650 Red highest return rate at 11.76% -- likely product quality issue
- Multiple Road-650 Red sizes in top 20 returns -- model specific problem not random
- All territories show consistent return rates between 2.04% and 2.37%
- Returns growing proportionally with sales -- no worsening trend detected
- Original returns query had JOIN error causing 100%+ rates -- fixed using subqueries

### Data Quality
- All customer key columns fully populated -- zero NULL values
- Zero NULL dates across all three sales tables
- No extra spaces found in customer name columns
- Names stored in ALL CAPS -- corrected using custom dbo.ProperCase function
- StockDate column contains dates from 2001 -- original inventory date, not sale related
- 123 customer records have no gender value recorded
  
### Time Intelligence
- 2015 was 100% bikes — Accessories and Clothing launched July 2016
- July 2016 inflection point explains every growth anomaly in the dataset
- 2017 reached $9M cumulative revenue in 6 months vs 12 months for 2015 and 2016
- 2016 grew 45.58% over 2015 — largest year over year jump in dataset
- Q2 is strongest quarter on average, Q3 is consistently weakest
- Two seasonal peaks: June and December separated by summer trough
- Day of week analysis shows flat distribution — consistent with online retail
- Bike revenue grew 37% in 2016 independent of new category launches
- Accessories on pace for $1M+ full year 2017 — 153% year over year growth
- First $10M took 19 months, second $10M took only 8 months

### Customer Analysis
- 73.87% of customers bought only once and never returned
- Only 298 customers (1.71%) bought across all three years
- At Risk segment holds $2.48M in revenue -- Maurice Shan top priority
- Road-150 Red single purchase churners: premium buyers lost before accessories launched
- Australia generates $2,131 per customer vs $1,111 for North America
- Top 31% of customers generate 82.61% of revenue
- $2,000-$4,999 spend band is revenue engine: 24% of customers, 52.47% of revenue
- 49.31% of customers spend under $500 generating only 2.88% of revenue
- Ideal customer: late 50s, Professional or Management, $80K-$110K, home owner, 4+ orders
- One ideal customer worth approximately 148x a typical low value buyer

### Returns Analysis
- Overall return rate 2.17% — healthy for retail (industry average 8-10%)
- Road-650 Red has model wide problem at 11.76% return rate across all sizes
- Mountain-100 sizes 44+ have elevated rates — sizes 38 and 42 have zero returns
- Only 6 products were sold and never returned
- Clothing returns driven by sizing — Caps at 1.11% (one size fits all) confirms root cause
- All territories between 2.04% and 2.37% — geography is not the problem
- Return rate stabilised at 2.1% from July 2016 onwards — healthy equilibrium reached
- $765,278 total revenue lost to returns — 3.07% of total revenue
- Mountain-200 highest absolute revenue loss despite moderate return rate — volume effect
- Top 22 products generate 64.6% of all returns — highly actionable concentration
- Bikes returned within 60 days on average — fit issues discovered immediately
- Accessories returned after 100+ days on average — quality or expectation mismatch
- Fixing top 22 problem products would eliminate nearly two thirds of all return volume
