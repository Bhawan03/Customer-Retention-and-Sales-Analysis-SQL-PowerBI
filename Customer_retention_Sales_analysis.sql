Create database superstore_db;

use superstore_db;

select * from superstore;

select count(*) from superstore;

desc superstore;

## Data Cleaning 
# Changing the column names
alter table superstore change `Order Id` Order_Id varchar(30);
alter table superstore change `Order Date` Order_Date text;
alter table superstore change `Ship Date` Ship_Date text;
alter table superstore change `Ship Mode` Ship_Mode text;
alter table superstore change `Customer Id` Customer_Id varchar(30);
alter table superstore change `Customer Name` Customer_Name varchar(30);
alter table superstore change `Postal Code` Postal_Code int;
alter table superstore change `Product Id` Product_Id text;
alter table superstore change `Sub-Category` Sub_Category text;
alter table superstore change `Product Name` Product_Name text;

select * from superstore limit 3;

# Droping Uncessary 'Row ID' Column
alter table superstore
drop column `﻿Row ID`;

# datatype conversion
select * from superstore limit 3;
desc superstore;

# changing datatypes of dates column 
SET SQL_SAFE_UPDATES = 0; # ensuring safe updates is on

UPDATE superstore
SET order_date = STR_TO_DATE(TRIM(order_date), '%d-%m-%Y');

alter table superstore
modify order_date date;
 
update superstore
set ship_date= str_to_date(trim(ship_date),'%d-%m-%Y');

alter table superstore
modify ship_date date;

# changing finance columns to decimal datatype for better accuracy
alter table superstore
modify sales decimal(10,2);

alter table superstore
modify profit decimal(10,2);

alter table superstore
modify Discount decimal(4,2);

select * from superstore limit 10;

select * from superstore # observed negative values in the profit section
where profit<0;

# hence creating a new column for clean profit values, preserving the original column as it is.
alter table superstore
add profit_clean decimal(10,2);

update superstore
set profit_clean=
case
	when profit<0 then 0
    else profit
end;

select profit,profit_clean from superstore 
where profit<0;

# alternate method for a quick check
select 
case 
when profit<0 then 0
else profit
end as profit_clean
from superstore;

select * from superstore limit 10;

# Checking for missing values in key columns
select 
count(order_id) as order_id_nulls,
count(customer_id) as customer_id_nulls,
count(product_id) as product_id_nulls,
count(sales) as sales_nulls,
count(profit) as profit_nulls
from superstore; -- Observed no missing values

# Adding Derived Columns

# Adding Ordered year and month columns
# order_year
alter table superstore
add Order_year int;

update superstore
set order_year=year(order_date);

# order_month
alter table superstore
add Order_month int;

update superstore
set order_month=month(order_date);

select * from superstore limit 3;

# Adding shipping days column to check the delay of shipping 
alter table superstore
add shipping_days int;

update superstore 
set shipping_days=datediff(ship_date,order_date);

select ship_date,order_date,shipping_days from superstore limit 5;

# Exploratory Data Analysis(EDA) and Business Insights

# Checking Total sales,profits,orders
select 
sum(sales) as Total_Sales,
sum(profit) as Total_Profit,
count(distinct(order_id)) as Total_Orders
from superstore;

# Total Sales by each Category

select category,sum(sales) as Total_Sales from superstore
group by category
order by Total_Sales desc;

# Top 10 Products by sales
select Product_Name , sum(sales) as Total_Sales from superstore 
group by Product_Name
order by Total_Sales desc
limit 10;

# Loss Making Products
select Product_Name,sum(Profit) as profit from superstore 
group by Product_Name
having profit<0
order by profit;

# Region wise Performance
select Region,
sum(sales) as sales,
sum(profit) as profit
from superstore
group by region
order by profit desc;

# Monthly Sales Trend 
select order_year,order_month, sum(sales) as Total_Sales from superstore 
group by order_year,order_month
order by order_year,order_month;

# Impact of Discount on Profit
select Discount,round(avg(Profit),2) as Average_Profit
from superstore 
group by Discount
order by Discount;

# Creating Views

# Sales Summary View
create view sales_summary as
select
category,
sum(sales) as Total_Sales,
sum(Profit) as Total_Profit
from superstore
group by category;

select * from sales_summary;

# Monthly Trend View
create view monthly_trend as
select
order_year,order_month,
sum(sales) as Total_Sales
from superstore
group by order_year,order_month
order by order_year,order_month;

select * from monthly_trend;

# Region wise Performance View
create view region_performance as
select 
region,
sum(sales) as Total_Sales,
sum(profit) as Total_Profit
from superstore 
group by region;

select * from region_performance;

# Top Products View
create view top_products as
select 
product_name,
sum(sales) as Total_Sales,
sum(profit) as Total_Profit
from superstore
group by Product_name
order by Total_Profit desc
limit 10;

select * from top_products;

# Top Customers View

create view top_customers as
select
customer_id,
customer_name,
sum(sales) as Total_sales
from superstore 
group by customer_id,customer_name
order by total_sales desc
limit 10;

select * from top_customers;

### Customer Retention analysis

# Customer life time value
select customer_id,customer_name,
round(sum(sales),2) as Total_sales,
round(sum(profit),2) as Total_Profit,
count(distinct order_id) as Total_Orders
from superstore
group by customer_id,customer_name
order by Total_sales desc;

# Repeat vs One Time Customers
select
case
	when order_count=1 then 'One-Time'
    else 'Repeat'
end as Customer_Type,
count(*) as customer_count
from(select customer_id, count(distinct order_id) as order_count
	 from superstore
     group by customer_id) t
group by customer_type;


## Year-wise Customer Retention Rate
select a.Order_year,
count(distinct a.customer_id) as Current_customers,
count(distinct b.customer_id)as Retained_customers,
round(count(distinct b.customer_id)* 100/ count(distinct a.customer_id),2) as Retention_rate
 from superstore a
left join superstore b
on a.customer_id=b.customer_id
and a.order_year=b.order_year-1
group by a.order_year
order by a.order_year;

# Customer Segmentation -> Recency+Frequency+Monetary Metrics(RFM) 

select max(order_date) from superstore;

select 
customer_id,
max(order_date) as Last_ordered,
datediff('2015-01-01',max(order_date)) as recency,
count(order_id) as frequency,
round(sum(sales),2) as monetary
from superstore 
group by customer_id;


# Profitability by category and sub-category

select 
category,
sub_category,
round(sum(sales),2) as Total_sales,
round(sum(profit),2) as Total_Profit,
round((sum(profit)/sum(sales)) * 100,2) as Profit_Margin,
case 
	when round((sum(profit)/sum(sales)) * 100,2) >0 then 'Positive'
    else 'Negative'
end as Profit_status
from superstore
group by category,sub_category;


# Impact of Discount on Sales and Profit

select 
discount,
round(avg(sales),2) as Avg_Sales,
round(avg(profit),2) as Avg_Profit,
case
	when round(avg(profit),2)>0 then 'Positive'
    else 'Negative'
end as Profit_status
from superstore 
group by discount
order by discount;


# Shipping Delay Impact

select 
    shipping_days,
    count(*) as orders,
    round(avg(profit),2) as avg_profit
from superstore
group by shipping_days
order by shipping_days;

# Creating Views

# Customer Summary
create view customer_summary as
select 
    customer_id,
    customer_name,
    sum(sales) as total_sales,
    sum(profit) as total_profit,
    count(distinct order_id) as total_orders
from superstore
group by customer_id, customer_name;

select * from customer_summary;

# RFM View
create view rfm_analysis as
select 
    customer_id,
    datediff('2015-01-01', max(order_date)) as recency,
    count(order_id) as frequency,
    sum(sales) as monetary
from superstore
group by customer_id;

select * from rfm_analysis;

# Discount Impact View
create view discount_impact as
select 
    discount,
    avg(sales) as avg_sales,
    avg(profit) as avg_profit
from superstore
group by discount;

select * from discount_impact;

# Shipping Analysis View
create view shipping_analysis as
select 
    shipping_days,
    avg(profit) as avg_profit
from superstore
group by shipping_days
order by shipping_days;

select * from shipping_analysis;

# Profit Margin KPI View
create view profit_analysis as
select 
    category,
    sub_category,
    sum(sales) as sales,
    sum(profit) as profit,
    round((sum(profit)/sum(sales))*100,2) as profit_margin
from superstore
group by category, sub_category;

select * from profit_analysis;

# RFM Scoring from rfm_analysis view

# 3-High , 2-Medium , 1-Low
create view rfm_scored as
select *,
case 
    when recency <= 30 then 3
    when recency <= 90 then 2
    else 1
end as r_score,

case 
    when frequency >= 5 then 3
    when frequency >= 2 then 2
    else 1
end as f_score,

case 
    when monetary >= 5000 then 3
    when monetary >= 1000 then 2
    else 1
end as m_score
from rfm_analysis;

select * from rfm_scored; 


# Customer Segments View from rf_scored view

create view customer_segments as
select *,
case 
    when r_score=3 and f_score=3 and m_score=3 then 'High Value'
    when r_score>=2 and f_score>=2 then 'Loyal'
    when r_score=1 then 'At Risk'
    else 'Low Value'
end as segment
from rfm_scored;

select * from customer_segments;