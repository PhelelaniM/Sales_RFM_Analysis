---First inspect the Data: View, Count and understand all the records and Columns.
SELECT * FROM [dbo].[Sales Dataset]
SELECT COUNT(*) FROM [dbo].[Sales Dataset]

---Checking Unique values
SELECT DISTINCT STATUS FROM [dbo].[Sales Dataset] -- Graphic in dashboard
SELECT DISTINCT QTR_ID FROM [dbo].[Sales Dataset] -- graphic in dashboard (Month vs QTR??)
SELECT DISTINCT MONTH_ID FROM [dbo].[Sales Dataset]
SELECT DISTINCT YEAR_ID FROM [dbo].[Sales Dataset] -- Annual trends plotted in dashboard
SELECT DISTINCT PRODUCTLINE FROM [dbo].[Sales Dataset] -- Graphic showing which product performed best
SELECT DISTINCT PRODUCTCODE FROM [dbo].[Sales Dataset]
SELECT DISTINCT CUSTOMERNAME FROM [dbo].[Sales Dataset]
SELECT DISTINCT CITY FROM [dbo].[Sales Dataset] -- maybe a top 10 in the world ranking by sales or performance?
SELECT DISTINCT STATE FROM [dbo].[Sales Dataset] -- Not relevant for how we want to plot geospatial data...
SELECT DISTINCT COUNTRY FROM [dbo].[Sales Dataset] -- Could be useful in our tableau world map...
SELECT DISTINCT TERRITORY FROM [dbo].[Sales Dataset] -- Geographic plotting in dashboard
SELECT DISTINCT DEALSIZE FROM [dbo].[Sales Dataset] -- nice to plot

---Count distinct values
SELECT COUNT (DISTINCT ORDERLINENUMBER) FROM [dbo].[Sales Dataset]

--ANALYSIS SECTION

--- Which product constitutes the highest percentage of overall sales
--1. Total sales per each product
SELECT PRODUCTLINE, 
SUM(SALES) as TOTAL_REVENUE
FROM [dbo].[Sales Dataset]
GROUP BY PRODUCTLINE

--2. Total sales for all products 
SELECT cast(SUM(TOTAL_REVENUE) as int) as Total_Sales_of_all_products
FROM (SELECT PRODUCTLINE, 
SUM(SALES) as TOTAL_REVENUE
FROM [dbo].[Sales Dataset]
GROUP BY PRODUCTLINE) as x;

--3. Find percentage of product category a percentage of all products (1/2)*100

;WITH total (PRODUCTLINE, TOTAL_REVENUE) as
	(SELECT PRODUCTLINE, 
		SUM(SALES) as TOTAL_REVENUE
		FROM [dbo].[Sales Dataset]
		GROUP BY PRODUCTLINE),
	total_of_all (Total_Sales_of_all_products) as 
	(SELECT cast(SUM(TOTAL_REVENUE) as int) as Total_Sales_of_all_products
FROM (SELECT PRODUCTLINE, 
SUM(SALES) as TOTAL_REVENUE
FROM [dbo].[Sales Dataset]
GROUP BY PRODUCTLINE) as x)

--Main Query:
SELECT PRODUCTLINE,ROUND(((total.TOTAL_REVENUE/total_of_all.Total_Sales_of_all_products)*100),2) as Percentage
FROM total,total_of_all
ORDER BY 2 DESC

--Analysis of Sales using aggregate by columns i.e, Group By
--1. Group By PRODUCTLINE
SELECT PRODUCTLINE, ROUND(SUM(SALES),2) as Revenue
FROM [dbo].[Sales Dataset]
GROUP BY PRODUCTLINE
ORDER BY 2 DESC
--Classic Cars were best performing product closely followed by Vintage Cars.

--2. Group By YEAR_ID
SELECT YEAR_ID, ROUND(SUM(SALES),2) as Revenue
FROM [dbo].[Sales Dataset]
GROUP BY YEAR_ID
ORDER BY 2 DESC
---2004 is the best performing year, followed by 2003 and 2005 had a very poor performance.
---lets see if they were fully operational in the whole of 2005..

--Operational Months in 2005
SELECT distinct MONTH_ID FROM [dbo].[Sales Dataset]
WHERE YEAR_ID = 2005
order by 1
--Turns out they only operated for 5 months in 2005.

--3. Group By DEALSIZE
SELECT DEALSIZE, ROUND(SUM(SALES),2) as Revenue
FROM [dbo].[Sales Dataset]
GROUP BY DEALSIZE
ORDER BY 2 DESC
--Medium size deals constituted the highest proportion of Sales and therefore require the most attention in terms of budget and marketing

--4. Group By COUNTRY
SELECT COUNTRY, ROUND(SUM(SALES),2) as Revenue
FROM [dbo].[Sales Dataset]
GROUP BY COUNTRY
ORDER BY 2 DESC

-- USA the strongest sales generator in the world, closely followed by Spain, France and Australia. 
--Lowest contributor is Ireland and Phillipines and may need to consider downsizing operations or pulling out of those countries.


--Analysis of best and worst performing Months in 2003
SELECT MONTH_ID, ROUND(SUM(SALES),2) as Revenue, COUNT(ORDERNUMBER) as Orders_Made
FROM [dbo].[Sales Dataset]
WHERE YEAR_ID = 2003
GROUP BY MONTH_ID
ORDER BY 2 DESC
--November i.e, 11 was the best performing month in terms of revenue and number of orders made. Year end and bonus spend for end of the year.
--January i.e, 1 was the worst performing month in terms of revenue and number of orders made. People are starting the new year and are generally financially conservative.


--Analysis of best and worst performing Months in 2004
SELECT MONTH_ID, ROUND(SUM(SALES),2) as Revenue, COUNT(ORDERNUMBER) as Orders_Made
FROM [dbo].[Sales Dataset]
WHERE YEAR_ID = 2004
GROUP BY MONTH_ID
ORDER BY 2 DESC
--Again we see that November is the best performing month. 
--Worst performing is March.


--Analysis of best performing product sold each month of each year.
SELECT YEAR_ID,MONTH_ID,
SUM(CASE WHEN PRODUCTLINE = 'Motorcycle' THEN 1 ELSE 0 END) as Motorcycles,
SUM(CASE WHEN PRODUCTLINE = 'Trains' THEN 1 ELSE 0 END) as Trains,
SUM(CASE WHEN PRODUCTLINE = 'Ships' THEN 1 ELSE 0 END) as Ships,
SUM(CASE WHEN PRODUCTLINE = 'Trucks and Buses' THEN 1 ELSE 0 END) as Trucks_and_Buses,
SUM(CASE WHEN PRODUCTLINE = 'Vintage Cars' THEN 1 ELSE 0 END) as Vintage_Cars,
SUM(CASE WHEN PRODUCTLINE = 'Classic Cars' THEN 1 ELSE 0 END) as Classic_Cars,
SUM(CASE WHEN PRODUCTLINE = 'Planes' THEN 1 ELSE 0 END) as Planes
FROM [dbo].[Sales Dataset]
GROUP BY YEAR_ID, MONTH_ID
ORDER BY 1,2
--Classic cars sold the most in January of 2002 and 2004, while 2005 has inomplete trading months.


--November seems to bee the month with strongest sales - What productperformed the best in terms of revenue in this month?
SELECT MONTH_ID,PRODUCTLINE,SUM(SALES),COUNT(ORDERNUMBER)
FROM [dbo].[Sales Dataset]
WHERE MONTH_ID  = 11 AND YEAR_ID = 2003
GROUP BY MONTH_ID,PRODUCTLINE
ORDER BY 3 DESC
--Classic Cars and Vintage cars were the strongest contributors to the excellent November sales.


--Question to be answered in the RFM Analysis:
--1. Who is our best customer 
--2. Recency: Last Order Date
--3. Frequency: Count of total orders
--4. Monetary Value: Total Spend

DROP TABLE IF EXISTS #rfm
;with rfm (CUSTOMERNAME,Order_Frequency,Monetary_Value,Average_Monetary_Value,Last_Order_Date,Max_Order_Date,Recency) as
(

SELECT CUSTOMERNAME,

COUNT(ORDERNUMBER) as Order_Frequency,
SUM(SALES)as Monetary_Value,
AVG(SALES)as Average_Monetary_Value,
MAX(ORDERDATE) as Last_Order_Date, -- THE MOST RECENT PURCHASE DATE
(SELECT MAX(ORDERDATE) FROM [dbo].[Sales Dataset]) as Max_Order_Date,
DATEDIFF(DD,MAX(ORDERDATE),(SELECT MAX(ORDERDATE) FROM [dbo].[Sales Dataset])) as Recency

FROM [dbo].[Sales Dataset]
GROUP BY CUSTOMERNAME
),
rfm_calc as
(
	SELECT q.*,
	NTILE(4) OVER (order by Recency desc) as rfm_recency,
	NTILE(4) OVER (order by Order_Frequency) as rfm_frequency,
	NTILE(4) OVER (order by Monetary_Value) as rfm_monetary

	FROM rfm as q
)
--Main Query that places all the ouytputs from cte into a temp table
SELECT 
	c.*,rfm_recency+rfm_frequency+rfm_monetary as rfm_cell,
	CAST(rfm_recency as varchar) + CAST(rfm_frequency as varchar) + CAST(rfm_monetary AS varchar) rfm_cell_string
into #rfm
FROM rfm_calc c


--Main Query that runs the temp table we just created
SELECT *
FROM #rfm


----SEGMENTATION ANALYSIS
SELECT CUSTOMERNAME, rfm_recency,rfm_frequency,rfm_monetary,
case
	when rfm_cell_string in (111,112,121,122,123,132,211,212,114,141,113) then 'lost customers' -- havent bought recently and buying very little and not very frequent...
	when rfm_cell_string in (133,134,143,244,334,343,344,144) then 'slipping away,cannot lose' -- big spending customers who arent buying lately
	when rfm_cell_string in (311,411,331) then 'new customers' -- they have bought recently and havent had high buying freuency or value piurchases
	when rfm_cell_string in (222,223,233,322) then 'potential churners'
	when rfm_cell_string in (323,333,321,422,332,432) then 'active'
	when rfm_cell_string in (433,434,443,444) then 'loyal'
	end as rfm_segment
FROM #rfm


--Additional CTE to count each category
;with counts (CUSTOMERNAME,rfm_recency,rfm_frequency,rfm_monetary,rfm_segment) as

(SELECT CUSTOMERNAME, rfm_recency,rfm_frequency,rfm_monetary,
case
	when rfm_cell_string in (111,112,121,122,123,132,211,212,114,141,113) then 'lost customers' -- havent bought recently and buying very little and not very frequent...
	when rfm_cell_string in (133,134,143,244,334,343,344,144) then 'slipping away,cannot lose' -- big spending customers who arent buying lately
	when rfm_cell_string in (311,411,331) then 'new customers' -- they have bought recently and havent had high buying freuency or value piurchases
	when rfm_cell_string in (222,223,233,322) then 'potential churners'
	when rfm_cell_string in (323,333,321,422,332,432) then 'active'
	when rfm_cell_string in (433,434,443,444) then 'loyal'
	end as rfm_segment
FROM #rfm)

select rfm_segment, COUNT(*) AS Number_of_Customers FROM counts
GROUP BY rfm_segment
ORDER BY 1 DESC
