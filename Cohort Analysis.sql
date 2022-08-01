-- DATA CLEANING


-- All records from the table = 541,909
-- Records without a customerID = 135,080

SELECT [InvoiceNo]
      ,[StockCode]
      ,[Description]
      ,[Quantity]
      ,[InvoiceDate]
      ,[UnitPrice]
      ,[CustomerID]
      ,[Country]
  FROM [PortfolioDB].[dbo].['Online Retail$']
  where CustomerID is null 

  -- We will bve working with rows where the customerID is not a null. 
  
  WITH online_retail AS (
	SELECT [InvoiceNo]
      ,[StockCode]
      ,[Description]
      ,[Quantity]
      ,[InvoiceDate]
      ,[UnitPrice]
      ,[CustomerID]
      ,[Country]
  FROM [PortfolioDB].[dbo].['Online Retail$']
  where CustomerID IS NOT NULL 
),

quantity_unit_price AS 
(
--397,884 with quantity and a unit price
	SELECT * FROM online_retail 
	WHERE Quantity > 0 AND UnitPrice > 0
)
, duplicate_check AS (

-- DUPLICATE CHECK
	SELECT * , ROW_NUMBER() OVER (PARTITION BY invoiceno, stockcode, quantity ORDER BY invoicedate) dup_flag
	FROM quantity_unit_price
)
--392,669 is the clean data for the cohort analysis
--5215 rows contained duplicates. 
	SELECT * INTO #online_retail_clean
	FROM duplicate_check
	WHERE dup_flag = 1

--CLEAN DATA FOR COHORT ANALYSIS

SELECT * FROM #online_retail_clean

 /* Data needed for Cohort Analysis:
 1. Unique Identifiers
 2. Initial start date
 3. Revenue Data 
 */

 SELECT CustomerID, 
		MIN (invoicedate) AS First_purchase_date,
		DATEFROMPARTS (year(min (invoicedate)), month(min(invoicedate)), 1) Cohort_date
INTO #Cohort
 FROM #online_retail_clean
 GROUP BY CustomerID

 SELECT * FROM #Cohort

--CREATING A COHORT INDEX
SELECT 
	mmm. *, 
	cohort_index = year_diff * 12 + month_diff + 1
	INTO #Cohort_retention
FROM (
		SELECT 
			mm. *, 
			year_diff = invoice_year - cohort_year, 
			month_diff = invoice_month - cohort_month
		FROM (
				SELECT 
					o. * , 
					c.Cohort_date,
					YEAR(o.invoicedate) Invoice_year, 
					MONTH (o.invoicedate) Invoice_month, 
					YEAR (c.cohort_date) Cohort_year, 
					MONTH(c.cohort_date) Cohort_month
				FROM #online_retail_clean o
				LEFT JOIN #Cohort c
					ON o.CustomerID = c.CustomerID
		)mm
	)mmm

SELECT * FROM #Cohort_retention

-- Pivot table to see the cohort details 
SELECT 
 * 
 INTO #cohort_pivot
FROM (
		SELECT DISTINCT customerID, Cohort_date, Cohort_index
		FROM #Cohort_retention
     ) tbl
PIVOT (
	COUNT (CustomerID) 
	FOR cohort_index in
	(
	[1],
	[2],
	[3],
	[4], 
	[5], 
	[6], 
	[7], 
	[8], 
	[9], 
	[10],
	[11],
	[12],
	[13])
) AS Pivot_table
ORDER BY Cohort_date

SELECT * FROM #cohort_pivot

SELECT  cohort_date, 
	(1.0 * [1]/[1] * 100) AS [1], 
	(1.0 * [2]/[1] * 100 ) AS [2], 
	(1.0 * [3]/[1] * 100 ) AS [3], 
	(1.0 * [4]/[1] * 100 ) AS [4], 
	(1.0 * [5]/[1] * 100 ) AS [5], 
	(1.0 * [6]/[1] * 100 ) AS [6], 
	(1.0 * [7]/[1] * 100 ) AS [7], 
	(1.0 * [8]/[1] * 100 ) AS [8], 
	(1.0 * [9]/[1] * 100 ) AS [9], 
	(1.0 * [10]/[1] * 100 ) AS [10], 
	(1.0 * [11]/[1] * 100 ) AS [11], 
	(1.0 * [12]/[1] * 100 ) AS [12], 
	(1.0 * [13]/[1] * 100 ) AS [13]
FROM #cohort_pivot
ORDER BY Cohort_date

