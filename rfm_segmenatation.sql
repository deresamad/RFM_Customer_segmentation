--Inspecting the data
select * FROM [dbo].[sales_data]
--Checking Unique value
--To check the different sales status in the database
select distinct status from [dbo].[sales_data]
--To check the years in which the sales data spans from
select distinct year_id from [dbo].[sales_data]
--To check the different product line
select distinct productline from [dbo].[sales_data]
--To check the countries were purchase was made from
select distinct country from [dbo].[sales_data]
--To check the different types of dealsize
select distinct dealsize from [dbo].[sales_data]
--To check diffent territories of purchase
select distinct territory from [dbo].[sales_data]


--To check the productline with the highest revenue
select Productline,sum(sales) revenue
from [dbo].[sales_data]
group by productline
order by 2 desc

--To check the year the highest revenue was made
select year_id,sum(sales) revenue
from [dbo].[sales_data]
group by year_id
order by 2 desc

--to check the months of operation in the year 2005
select distinct month_id from [dbo].[sales_data]
where year_id=2005

--to check the dealsize that generated the highest revenue
select dealsize,sum(sales) revenue
from [dbo].[sales_data]
group by dealsize
order by 2 desc

--the best month of the year by the number of orders[frequency] and revenue generated
select month_id,sum(sales),count(ordernumber)
from [dbo].[sales_data]
group by month_id
order by 2 desc

--November seems to be the month, to check what products were sold in november
select month_id,productline,count(ordernumber) frequency,sum(sales) revenue
from [dbo].[sales_data]
where year_id=2003 and month_id=11
group by month_id,productline
order by 3 desc

--to check who is the best customer using RFM analysis (Recency,Frequency,Monetary)
DROP TABLE IF EXISTS #rfm
;with rfm as 
(
select 

	Customername, 
	sum(sales) MonetaryValue,
	avg(sales) AvgMonetaryValue,
	count(Ordernumber) Frequency,
    max(Orderdate) last_order_date,
	(select max(Orderdate) from [dbo].[sales_data]) max_order_date,
	DATEDIFF(DD, max(Orderdate), (select max(Orderdate) from [dbo].[sales_data])) Recency
from [dbo].[sales_data]
group by Customername
),
rfm_calc as
(
	select r.*,
			NTILE(4) OVER (order by Recency desc) rfm_recency,
			NTILE(4) OVER (order by Frequency) rfm_frequency,
			NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*,rfm_recency+rfm_frequency+rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar)+ cast(rfm_monetary as varchar)rfm_cell_string
into #rfm
from rfm_calc c



select customername , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

--what products are most often sold together
select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from [dbo].[sales_data] p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM [dbo].[sales_data]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from [dbo].[sales_data] s
order by 2 desc



--What city has the highest number of sales in a specific country
select city, sum (sales) Revenue
from [dbo].[sales_data]
where country = 'UK'
group by city
order by 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [PortfolioDB].[dbo].[sales_data_sample]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc
