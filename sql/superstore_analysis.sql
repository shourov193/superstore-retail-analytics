USE super_store;
 
CREATE TABLE clean_superstore (
    Row_ID            INT,
    Order_ID          VARCHAR(30),
    Order_Date        DATE,
    Ship_Date         DATE,
    Ship_Mode         VARCHAR(30),
    Customer_ID       VARCHAR(20),
    Customer_Name     VARCHAR(100),
    Segment           VARCHAR(20),
    Country           VARCHAR(30),
    City              VARCHAR(50),
    State             VARCHAR(50),
    Postal_Code       VARCHAR(10),
    Region            VARCHAR(20),
    Product_ID        VARCHAR(20),
    Category          VARCHAR(30),
    Sub_Category      VARCHAR(30),
    Product_Name      VARCHAR(200),
    Sales             DECIMAL(10,2),
    Quantity          INT,
    Discount          DECIMAL(5,2),
    Profit            DECIMAL(10,2),
    Processing_Days   INT,
    Profit_Margin_Pct DECIMAL(8,4),
    Profit_Status     VARCHAR(20),
    Order_Year        INT,
    Order_Month       INT,
    Order_Quarter     VARCHAR(5),
    Discount_Band     VARCHAR(30),
    Revenue_Band      VARCHAR(30)
);

-- Check the imported table --
select * from clean_superstore;

-- Analysis Query 1: Overall KPIs --
SELECT
    COUNT(DISTINCT Order_ID)                     AS total_orders,
    COUNT(DISTINCT Customer_ID)                  AS unique_customers,
    ROUND(SUM(Sales), 2)                         AS total_revenue,
    ROUND(SUM(Profit), 2)                        AS total_profit,
    ROUND(SUM(Profit)/SUM(Sales)*100, 1)         AS overall_margin_pct,
    SUM(CASE WHEN Profit < 0 THEN 1 ELSE 0 END) AS loss_line_count,
    ROUND(SUM(CASE WHEN Profit<0 THEN Profit ELSE 0 END), 2) AS total_loss_value
FROM clean_superstore;

-- Analysis Query 2: Revenue and Profit by Category -- 
SELECT
    Category,
    COUNT(DISTINCT Order_ID)              AS orders,
    ROUND(SUM(Sales), 2)                  AS revenue,
    ROUND(SUM(Profit), 2)                 AS profit,
    ROUND(SUM(Profit)/SUM(Sales)*100, 1)  AS margin_pct
FROM clean_superstore
GROUP BY Category
ORDER BY revenue DESC;

-- Analysis Query 3: Sub-Category Profitability (Key Insight Query)--
-- THIS REVEALS THW HEADLINE BUSINESS FINDING:
-- Some sub-categories lose money DESPITE having high revenue.
SELECT
    Category,
    Sub_Category,
    ROUND(SUM(Sales), 2)                  AS revenue,
    ROUND(SUM(Profit), 2)                 AS profit,
    ROUND(SUM(Profit)/SUM(Sales)*100, 1)  AS margin_pct,
    SUM(CASE WHEN Profit<0 THEN 1 ELSE 0 END) AS loss_rows
FROM clean_superstore
GROUP BY Category, Sub_Category
ORDER BY profit ASC;   -- Worst first

-- Analysis Query 4: The Discount Trap--
-- MOST IMPACTFUL INSIGHT:
-- Heavy discounting produces NEGATIVE average profit margins.
SELECT
    Discount_Band,
    COUNT(*) AS order_lines,
    ROUND(SUM(Sales), 2)                     AS revenue,
    ROUND(SUM(Profit), 2)                    AS profit,
    ROUND(AVG(Profit_Margin_Pct)*100, 1)     AS avg_margin_pct
FROM clean_superstore
GROUP BY Discount_Band
ORDER BY FIELD(Discount_Band,
    'No Discount','Low (1-10%)','Med (11-20%)','High (21-30%)','Very High (30%+)');


-- Analysis Query 5: Year-over-Year Revenue Growth--
WITH yearly AS (
    SELECT Order_Year,
        ROUND(SUM(Sales),2)  AS revenue,
        ROUND(SUM(Profit),2) AS profit
    FROM clean_superstore
    GROUP BY Order_Year
)
SELECT
    Order_Year,
    revenue,
    profit,
    LAG(revenue) OVER (ORDER BY Order_Year) AS prev_year_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY Order_Year))
        / LAG(revenue) OVER (ORDER BY Order_Year) * 100, 1
    ) AS yoy_growth_pct
FROM yearly;

-- Analysis Query 6: State Ranking by Region --
SELECT
    Region,
    State,
    ROUND(SUM(Sales),2)                  AS revenue,
    ROUND(SUM(Profit),2)                 AS profit,
    ROUND(SUM(Profit)/SUM(Sales)*100,1)  AS margin_pct,
    RANK() OVER (PARTITION BY Region ORDER BY SUM(Profit) DESC) AS state_rank
FROM clean_superstore
GROUP BY Region, State
ORDER BY Region, state_rank;

-- Analysis Query 7: Top 10 Profitable Customers --
SELECT
    Customer_Name,
    Segment,
    COUNT(DISTINCT Order_ID)   AS orders,
    ROUND(SUM(Sales),2)        AS revenue,
    ROUND(SUM(Profit),2)       AS profit
FROM clean_superstore
GROUP BY Customer_Name, Segment
ORDER BY profit DESC
LIMIT 10;


-- Create Final View -- 

USE super_store;
 
-- Sub-category performance view
CREATE OR REPLACE VIEW vw_subcat AS
SELECT Category, Sub_Category,
    ROUND(SUM(Sales),2) AS revenue,
    ROUND(SUM(Profit),2) AS profit,
    ROUND(SUM(Profit)/SUM(Sales)*100,1) AS margin_pct,
    COUNT(*) AS order_lines
FROM clean_superstore
GROUP BY Category, Sub_Category;
 
-- Discount impact view
CREATE OR REPLACE VIEW vw_discount AS
SELECT Discount_Band,
    COUNT(*) AS order_lines,
    ROUND(SUM(Sales),2) AS revenue,
    ROUND(SUM(Profit),2) AS profit,
    ROUND(AVG(Profit_Margin_Pct)*100,1) AS avg_margin_pct
FROM clean_superstore
GROUP BY Discount_Band;
 
-- State performance view
CREATE OR REPLACE VIEW vw_state AS
SELECT Region, State,
    ROUND(SUM(Sales),2) AS revenue,
    ROUND(SUM(Profit),2) AS profit,
    ROUND(SUM(Profit)/SUM(Sales)*100,1) AS margin_pct
FROM clean_superstore
GROUP BY Region, State;
 
-- Main fact view
CREATE OR REPLACE VIEW vw_main AS
SELECT * FROM clean_superstore;
 
SELECT COUNT(*) FROM vw_main;  -- 9,994

select * from vw_main;
select * from vw_state;
select * from vw_subcat;
select * from vw_discount;

