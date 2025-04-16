use ecomm;
select * from customer_churn;

-- Data Cleaning --
-- Handling Missing Values and Outliers --

-- WarehouseToHome --
set sql_safe_updates = 0;
set @avg_WarehouseToHome=(select round(avg(WarehouseToHome))as avg_WarehouseToHome from customer_churn);
update customer_churn
set WarehouseToHome = @avg_WarehouseToHome
where WarehouseToHome is null;

-- HourSpendOnApp --

set @avg_HourSpendOnApp=(select round(avg(HourSpendOnApp))as avg_HourSpendOnApp from customer_churn);
update customer_churn
set HourSpendOnApp = @avg_HourSpendOnApp
where HourSpendOnApp is null;

-- OrderAmountHikeFromlastYear --
set @avg_OrderAmountHikeFromlastYear=(select round(avg(OrderAmountHikeFromlastYear))as avg_OrderAmountHikeFromlastYear from customer_churn);
update customer_churn
set OrderAmountHikeFromlastYear = @avg_OrderAmountHikeFromlastYear
where OrderAmountHikeFromlastYear is null;

-- DaySinceLastOrder --
set @avg_DaySinceLastOrder=(select round(avg(DaySinceLastOrder))as avg_DaySinceLastOrder from customer_churn);
update customer_churn
set DaySinceLastOrder = @avg_DaySinceLastOrder
where DaySinceLastOrder is null;


--  Impute mode for the following columns: Tenure, CouponUsed, OrderCount --
set@tenure_mode = (select tenure from customer_churn group by tenure order by count(*) desc limit 1);
update customer_churn
set Tenure =@Tenure_mode
where Tenure is null;

-- couponUsed --
set@couponUsed_mode = (select couponUsed from customer_churn group by couponUsed order by count(*) desc limit 1);
update customer_churn
set couponUsed =@couponUsed_mode
where couponUsed is null;


-- OrderCount --
set@OrderCount_mode = (select OrderCount from customer_churn group by Ordercount order by count(*) desc limit 1);
update customer_churn
set OrderCount =@OrderCount_mode
where OrderCount is null;



/*  Handle outliers in the 'WarehouseToHome' column by deleting rows where the
values are greater than 100*/


delete from customer_churn
where WarehouseToHome > 100 ;

-- Dealing with Inconsistencies --
-- replace occurances --

update customer_churn
set PreferredLoginDevice = replace(PreferredLoginDevice, 'Phone', 'Mobile Phone')
where PreferredLoginDevice like '%Phone%';


update customer_churn
set PreferedOrderCat = replace(PreferedOrderCat, 'Mobile', 'Mobile Phone')
where PreferedOrderCat like'%Mobile%';


--  Standardize payment mode values-
update customer_churn
set PreferredPaymentMode = replace(PreferredPaymentMode, 'COD', 'Cash on Delivery')
where PreferredPaymentMode like '%COD%';

update customer_churn
set PreferredPaymentMode = replace(PreferredPaymentMode, 'CC', 'Credit Card')
where PreferredPaymentMode like '%CC%';



-- Data Transformation --
-- Column Renaming --
--  Rename the column "PreferedOrderCat" to "PreferredOrderCat"--

alter table customer_churn
rename column PreferedOrderCat to PreferredOrderCat;

alter table customer_churn
rename column HourSpendOnApp to HoursSpentOnApp;



-- Creating New Columns --
-- Create a new column named ‘ComplaintReceived’ with values "Yes" if the
-- corresponding value in the ‘Complain’ is 1, and "No" otherwise.


alter table customer_churn
add column ComplaintReceived enum ('yes','no');

update customer_churn
set ComplaintReceived = if(complain = 1 , 'yes', 'no');


--  Create a new column named 'ChurnStatus --

alter table customer_churn
add column churnStatus enum ('churned', 'active');

update customer_churn
set churnStatus = if (churn = 1, 'churned', 'active');


-- Column Dropping --
-- Drop the columns "Churn" and "Complain" from the table

alter table customer_churn
drop column churn,
drop column complain;


-- Data Exploration and Analysis:
--  Retrieve the count of churned and active customers from the dataset --
select count(*) churned from customer_churn;
select count(*) active_customer from customer_churn;

-- Display the average tenure and total cashback amount of customers who churned. --
select ChurnStatus, avg(Tenure) as avg_tenure,
sum(CashbackAmount) as total_CashbackAmount from customer_churn 
where churnStatus = 'churned' group by churnStatus;


-- Determine the percentage of churned customers who complained --
select ComplaintReceived, concat(round(count(*)/(select count(*) from customer_churn)*100,2),'%')
as churned_percentage from customer_churn group by ComplaintReceived;

-- Find the gender distribution of customers who complained--
select Gender, COUNT(*) as ComplaintReceived_count
from customer_churn where ComplaintReceived = 'yes' group by Gender;

-- Identify the city tier with the highest number of churned customers whose
-- preferred order category is Laptop & Accessory
select CityTier, COUNT(*) as churnStatus FROM customer_churn
where Churnstatus and PreferredOrderCat = 'Laptop & Accessory'
group by CityTier
order by churnStatus Desc limit 1;

-- Identify the most preferred payment mode among active customers --
select PreferredPaymentMode, COUNT(*) as PaymentModeCount
from customer_churn where ChurnStatus = 'active'
group by PreferredPaymentMode order by PaymentModeCount desc limit 1; 


-- Calculate the total order amount hike from last year for customers who are single
-- and prefer mobile phones for ordering
select SUM(OrderAmountHikeFromlastYear) AS TotalOrderAmountHike
from customer_churn
where MaritalStatus = 'Single' and PreferredOrderCat = 'Mobile Phone';

-- Find the average number of devices registered among customers who used UPI as
-- their preferred payment mode
select avg(NumberOfDeviceRegistered) as AverageNumberOfDevices
from customer_churn
where PreferredPaymentMode = 'UPI';


-- Determine the city tier with the highest number of customers --
select CityTier, COUNT(*) as NumberOfCustomers
from customer_churn
group by CityTier
order by NumberOfCustomers desc limit 1;


--  Identify the gender that utilized the highest number of coupons --

select Gender, COUNT(*) as CouponUsageCount
from customer_churn where CouponUsed = 1
group by Gender
order by CouponUsageCount desc limit 1;


-- List the number of customers and the maximum hours spent on the app in each
-- preferred order category

select PreferredOrderCat, COUNT(distinct CustomerID) as NumberOfCustomers,
MAX(HoursSpentOnApp) as MaxHoursSpentOnApp
from customer_churn
group by PreferredOrderCat;


-- Calculate the total order count for customers who prefer using credit cards and
-- have the maximum satisfaction score.

select sum(ordercount) as total_ordercount,
max(SatisfactionScore) as maximum_Satifaction_Score from customer_churn
where preferredpaymentmode = 'credit card';


-- How many customers are there who spent only one hour on the app and days
-- since their last order was more than 5?

select COUNT(distinct CustomerID) as NumberOfCustomers
from customer_churn where HoursSpentOnApp = 1
and DaySinceLastOrder > 5;


-- What is the average satisfaction score of customers who have complained --

select avg(SatisfactionScore) as AverageSatisfactionScore
from customer_churn
where ComplaintReceived = 1;

--  List the preferred order category among customers who used more than 5 coupons.

select PreferredOrderCat, COUNT(*) as NumberOfCustomers
from customer_churn where CouponUsed > 5
group by PreferredOrderCat;

--  List the top 3 preferred order categories with the highest average cashback amount.

select PreferredOrderCat, avg(CashbackAmount) as AverageCashbackAmount
from customer_churn group by PreferredOrderCat
order by AverageCashbackAmount desc limit 3;


--  Find the preferred payment modes of customers whose average tenure is 10
-- months and have placed more than 500 orders.

Select PreferredPaymentMode, avg(tenure) as avg_tenure,count(ordercount) from customer_churn
group by preferredpaymentmode 
order by avg_tenure desc limit 3;

/* Categorize customers based on their distance from the warehouse to home such
as 'Very Close Distance' for distances <=5km, 'Close Distance' for <=10km,
'Moderate Distance' for <=15km, and 'Far Distance' for >15km. Then, display the
churn status breakdown for each distance category */


select
case
   when WarehouseToHome <= 5 then 'Very Close Distance'
   when WarehouseToHome <= 10 then 'Close Distance'
   when WarehouseToHome <= 15 then 'Moderate Distance'
   else 'Far Distance'
    end as category_distance, ChurnStatus, COUNT(*) as CustomerCount
from customer_churn
group by category_distance, churnstatus
order by category_distance, churnstatus;



/* List the customer’s order details who are married, live in City Tier-1, and their
order counts are more than the average number of orders placed by all
customers */


-- without using CTE
 select customerID , round(avg(ordercount)) as avg_ordercount from customer_churn
 where maritalstatus = 'married' and citytier = 1
 group by customerID
 having avg_ordercount > (select avg(ordercount) from customer_churn)
 order by avg_ordercount ; 


-- using CTE
 with average_order_count as (select round(avg(ordercount))
 as avg_order from customer_churn)
 select customerId, round(avg(ordercount)) as order_count from customer_churn
 where maritalstatus = 'married' and citytier = 1
 group by customerID
 having (select avg_order from average_order_count) < order_count
 order by order_count ;
 
 
 -- Create a ‘customer_returns’ table in the ‘ecomm’ database and insert the following data:
 
  create table ecomm.customer_returns (
    ReturnID INT primary key,
    CustomerID INT,
    ReturnDate DATE,
    RefundAmount DECIMAL(10, 2)
);


 insert into ecomm.customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount) 
values
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);


-- Display the return details along with the customer details of those who have
-- churned and have made complaints


select
c.CustomerID,
c.complaintreceived,
c.churnstatus,
r.ReturnID,
r.ReturnDate,
r.RefundAmount
From customer_churn c
join customer_returns r on c.customerID = r.customerID
where complaintreceived = 'yes' and churnstatus = 'churned';


select * from customer_churn;