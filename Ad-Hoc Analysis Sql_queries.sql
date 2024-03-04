CREATE DATABASE retail_events_db;

USE retail_events_db;


CREATE TABLE campaigns
	(
		campaign_id	VARCHAR(25) PRIMARY KEY,
        campaign_name VARCHAR(20),
        start_date VARCHAR(20),
        end_date VARCHAR(20)
	);
    
    
CREATE TABLE products
	(
		product_code VARCHAR(25) PRIMARY KEY,	
        product_name VARCHAR(50),
        category VARCHAR(30)
    );
    
CREATE TABLE stores
	(
		store_id VARCHAR(25) PRIMARY KEY,
        city VARCHAR(20)
    );
    

CREATE TABLE events
	(
		event_id VARCHAR(25) PRIMARY KEY,
        store_id VARCHAR(25),
        campaign_id	VARCHAR(25),
        product_code VARCHAR(25),
        base_price INT,
        promo_type VARCHAR(25),
        quantity_sold_before_promo INT,		
        quantity_sold_after_promo INT
    );



-- 1) provide a list of products with a base price
-- greater than 500 and that are featured in promo
-- type of 'BOGOF' (buy one get one free). this
-- information will help us identify high-value 
-- products that are currently being heavily discounted
-- , which can be useful for evaluating our pricing
-- and promotion stategies. 

SELECT Distinct p.product_name, e.base_price, e.promo_type
FROM events e
JOIN products p
ON e.product_code=p.product_code
WHERE base_price > 500 and promo_type = 'BOGOF';


-- 2)  generate a report that provides an overview of
-- the number of stores in each city. The result will
-- be sorted in descending order of store counts,
-- allowing us to identify the cities with the highest
-- store presence. The report includes two essentail
-- fields: city and store count, which will assist in
-- optimizing our retail operations.

SELECT city, count(*) store_count
FROM stores
GROUP BY city
ORDER BY store_count Desc;


-- 3) Generate a report that displays each campaign
-- along with the total revenue generated before and 
-- after campaign? The report includes three key fields
-- campaign_name, total_revenue(before_promotion),
-- total_revenue(after_promotion). This report should help
-- in evaluating the financial impact of our promotional
-- campaigns.(Display the values in millions)
 
WITH cte as
(
SELECT c.campaign_name, 
		SUM(e.base_price * quantity_sold_before_promo) total_revenue_before_promotion, 
        SUM(e.base_price * quantity_sold_after_promo) total_revenue_after_promotion
FROM events e
JOIN campaigns c
ON e.campaign_id = c.campaign_id
GROUP BY c.campaign_name
)

SELECT campaign_name, 
	   ROUND((total_revenue_before_promotion/1000000),2) 
       total_revenue_before_promotion_in_millions, 
	   ROUND((total_revenue_after_promotion/1000000),2) 
       total_revenue_after_promotion_in_millions
FROM cte;


-- 4) Produce a report that calculates the Incremental Sold
-- Quantity (ISU%) for each category during the diwali campaign.
-- Addionally, provide rankings for the categories based on their
-- ISU%. The report will include three key fields: category,
-- isu%, and rank order. This information will assist in assessing
-- the category-wise success and impact of the diwali campaign
-- on incremental sales.

-- Note: ISU% (Incremental Sold Quantity Percentage) is calculated 
-- as the percentage increase/decrease in quantity sold
-- (after promo) compared to quantity sold (before promo)

WITH cte as
(
SELECT p.category, 
	   ROUND((SUM(e.quantity_sold_after_promo) - SUM(e.quantity_sold_before_promo)) / 
       SUM(e.quantity_sold_before_promo) * 100,2) AS ISU_Percentage
FROM events e
JOIN campaigns c
ON e.campaign_id = c.campaign_id
JOIN products p
ON e.product_code = p.product_code
WHERE c.campaign_name = 'diwali'
GROUP BY p.	category
)

SELECT *,
	ROW_NUMBER() OVER(ORDER BY ISU_Percentage DESC) AS rank_order
FROM cte;


-- 5) Create a report featuring the Top 5 products, ranked by
-- Incremental Revenue Percentage (IR%) across all campaigns. The
-- report will provide essential information including product name,
-- category, and ir%. This analysis helps identify the most successful
-- products in terms of incremental revenue across our campaigns,
-- assisting in product optimization.


SELECT p.product_name, category,
	   ROUND((SUM(e.quantity_sold_after_promo * base_price) - 
       SUM(e.quantity_sold_before_promo * base_price))
       /SUM(e.quantity_sold_before_promo * base_price)*100,2) AS ir_percentage
FROM events e
JOIN products p
ON e.product_code = p.product_code
GROUP BY p.product_name, p.category
ORDER BY ir_percentage DESC
LIMIT 5;

