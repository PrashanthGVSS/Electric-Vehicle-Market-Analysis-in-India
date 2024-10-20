CREATE TABLE dim_date (
    date DATE PRIMARY KEY,
    fiscal_year VARCHAR(10),
    quarter VARCHAR(5)
);

CREATE TABLE electric_vehicle_sales_by_maker (
    date DATE,
    vehicle_category VARCHAR(50),
    maker VARCHAR(50),
    electric_vehicles_sold INT,
    PRIMARY KEY (date, vehicle_category, maker),
    FOREIGN KEY (date) REFERENCES dim_date(date)
);

CREATE TABLE electric_vehicle_sales_by_state (
    date DATE,
    state VARCHAR(50),
    vehicle_category VARCHAR(50),
    electric_vehicles_sold INT,
    total_vehicles_sold INT,
    PRIMARY KEY (date, state, vehicle_category),
    FOREIGN KEY (date) REFERENCES dim_date(date)
);

UPDATE electric_vehicle_sales_by_maker
SET `ï»¿date` = STR_TO_DATE(`ï»¿date`, '%d-%b-%y');

ALTER TABLE electric_vehicle_sales_by_maker 
CHANGE `ï»¿date` `date` DATE;

SELECT DISTINCT fiscal_year
FROM dim_date
WHERE fiscal_year IN ('2023', '2024');

SELECT DISTINCT vehicle_category
FROM electric_vehicle_sales_by_maker;

SELECT MIN(date) AS start_date, MAX(date) AS end_date
FROM dim_date;

SELECT MIN(date) AS start_date, MAX(date) AS end_date
FROM electric_vehicle_sales_by_maker;

UPDATE dim_date
SET `ï»¿date` = STR_TO_DATE(`ï»¿date`, '%d-%b-%y');
ALTER TABLE dim_date 
CHANGE `ï»¿date` `date` DATE;

SELECT MIN(date) AS start_date, MAX(date) AS end_date
FROM dim_date;

UPDATE electric_vehicle_sales_by_state
SET `ï»¿date` = STR_TO_DATE(`ï»¿date`, '%d-%b-%y');


ALTER TABLE electric_vehicle_sales_by_state
CHANGE `ï»¿date` `date` DATE;

# Task 1: List the Top 3 and Bottom 3 Makers for the Fiscal Years 2023 and 2024 in Terms of the Number of 2-Wheelers Sold

SELECT maker, SUM(electric_vehicles_sold) AS total_sales
FROM electric_vehicle_sales_by_maker ev
JOIN dim_date dd ON ev.date = dd.date
WHERE dd.fiscal_year IN ('2023', '2024') 
  AND ev.vehicle_category = '2-Wheelers'
GROUP BY maker
ORDER BY total_sales DESC
LIMIT 3;

SELECT maker, SUM(electric_vehicles_sold) AS total_sales
FROM electric_vehicle_sales_by_maker ev
JOIN dim_date dd ON ev.date = dd.date
WHERE dd.fiscal_year IN ('2023', '2024') 
  AND ev.vehicle_category = '2-WheelerS'
GROUP BY maker
ORDER BY total_sales ASC
LIMIT 3;

#Task 2: Identify the Top 5 States with the Highest Penetration Rate in 2-Wheeler and 4-Wheeler EV Sales in FY 2024?

SELECT state, vehicle_category, 
       SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) * 100 AS penetration_rate
FROM electric_vehicle_sales_by_state ev
JOIN dim_date dd ON ev.date = dd.date
WHERE dd.fiscal_year = '2024'
GROUP BY state, vehicle_category
ORDER BY penetration_rate DESC
LIMIT 5;

WITH PenetrationRates AS (
    SELECT state, vehicle_category, 
           SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) * 100 AS penetration_rate
    FROM electric_vehicle_sales_by_state ev
    JOIN dim_date dd ON ev.date = dd.date
    WHERE dd.fiscal_year = '2024'
    AND vehicle_category = '4-Wheelers'
    GROUP BY state, vehicle_category
)
SELECT state, penetration_rate
FROM PenetrationRates
ORDER BY penetration_rate DESC
LIMIT 5;

Task 3: List the States with Negative Penetration (Decline) in EV Sales from 2022 to 2024

SELECT state, 
       SUM(CASE WHEN dd.fiscal_year = '2022' THEN electric_vehicles_sold END) AS sales_2022,
       SUM(CASE WHEN dd.fiscal_year = '2024' THEN electric_vehicles_sold END) AS sales_2024
FROM electric_vehicle_sales_by_state ev
JOIN dim_date dd ON ev.date = dd.date
GROUP BY state
HAVING sales_2024 < sales_2022;

#Task 4: Quarterly Trends Based on Sales Volume for the Top 5 EV Makers (4-Wheelers) from 2022 to 2024
SELECT maker, dd.fiscal_year, dd.quarter, 
       SUM(electric_vehicles_sold) AS total_sales
FROM electric_vehicle_sales_by_maker ev
JOIN dim_date dd ON ev.date = dd.date
WHERE dd.fiscal_year IN ('2022', '2023', '2024')
  AND ev.vehicle_category = '4-Wheelers'
GROUP BY maker, dd.fiscal_year, dd.quarter
ORDER BY total_sales DESC
LIMIT 5;

#Task 5: Compare EV Sales and Penetration Rates in Delhi vs. Karnataka for 2024
-- Sales Comparison
SELECT state, SUM(electric_vehicles_sold) AS total_ev_sales
FROM electric_vehicle_sales_by_state ev
JOIN dim_date dd ON ev.date = dd.date
WHERE dd.fiscal_year = '2024'
  AND state IN ('Delhi', 'Karnataka')
GROUP BY state;

-- Penetration Rate Comparison
SELECT state, 
       SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) * 100 AS penetration_rate
FROM electric_vehicle_sales_by_state ev
JOIN dim_date dd ON ev.date = dd.date
WHERE dd.fiscal_year = '2024'
  AND state IN ('Delhi', 'Karnataka')
GROUP BY state;

#Task 6: Calculate the Compounded Annual Growth Rate (CAGR) in 4-Wheeler Units for the Top 5 Makers from 2022 to 2024
WITH sales_data AS (
    SELECT maker, 
           SUM(CASE WHEN dd.fiscal_year = '2022' THEN ev.electric_vehicles_sold END) AS sales_2022,
           SUM(CASE WHEN dd.fiscal_year = '2024' THEN ev.electric_vehicles_sold END) AS sales_2024
    FROM electric_vehicle_sales_by_maker ev
    JOIN dim_date dd ON ev.date = dd.date
    WHERE ev.vehicle_category = '4-Wheelers'
      AND dd.fiscal_year IN ('2022', '2024')
    GROUP BY maker
)
SELECT maker, sales_2022, sales_2024,
       ROUND(POW((sales_2024 / sales_2022), 1/2.0) - 1, 4) AS cagr
FROM sales_data
WHERE sales_2022 > 0 
ORDER BY cagr DESC
LIMIT 5;

#Task 7: List the Top 10 States That Had the Highest Compounded Annual Growth Rate (CAGR) from 2022 to 2024 in Total Vehicles Sold
WITH sales_by_state AS (
    SELECT state, 
           SUM(CASE WHEN dd.fiscal_year = '2022' THEN ev.total_vehicles_sold END) AS total_sales_2022,
           SUM(CASE WHEN dd.fiscal_year = '2024' THEN ev.total_vehicles_sold END) AS total_sales_2024
    FROM electric_vehicle_sales_by_state ev
    JOIN dim_date dd ON ev.date = dd.date
    WHERE dd.fiscal_year IN ('2022', '2024')
    GROUP BY state
)
SELECT state, total_sales_2022, total_sales_2024,
       ROUND(POW((total_sales_2024 / total_sales_2022), 1/2.0) - 1, 4) AS cagr
FROM sales_by_state
WHERE total_sales_2022 > 0 
ORDER BY cagr DESC
LIMIT 10;

#Task 8: Identify the Peak and Low Season Months for EV Sales from 2022 to 2024
SELECT MONTHNAME(dd.date) AS month, 
       SUM(ev.electric_vehicles_sold) AS total_sales
FROM electric_vehicle_sales_by_maker ev
JOIN dim_date dd ON ev.date = dd.date
WHERE dd.fiscal_year IN ('2022', '2023', '2024')
GROUP BY month
ORDER BY total_sales DESC;

#Task 9: Project the Number of EV Sales (Including 2-Wheelers and 4-Wheelers) for the Top 10 States by Penetration Rate in 2030
WITH penetration_rate_2024 AS (
    SELECT state, 
           SUM(electric_vehicles_sold) / SUM(total_vehicles_sold) * 100 AS penetration_rate
    FROM electric_vehicle_sales_by_state ev
    JOIN dim_date dd ON ev.date = dd.date
    WHERE dd.fiscal_year = '2024'
    GROUP BY state
)
SELECT state, penetration_rate
FROM penetration_rate_2024
ORDER BY penetration_rate DESC
LIMIT 10;

WITH cagr_sales AS (
    SELECT state, 
           SUM(CASE WHEN dd.fiscal_year = '2022' THEN ev.electric_vehicles_sold END) AS sales_2022,
           SUM(CASE WHEN dd.fiscal_year = '2024' THEN ev.electric_vehicles_sold END) AS sales_2024
    FROM electric_vehicle_sales_by_state ev
    JOIN dim_date dd ON ev.date = dd.date
    WHERE dd.fiscal_year IN ('2022', '2024')
    GROUP BY state
),
top_states AS (
    SELECT state
    FROM penetration_rate_2024
    ORDER BY penetration_rate DESC
    LIMIT 10
)
SELECT cs.state, cs.sales_2024, 
       ROUND(cs.sales_2024 * POW((1 + (POW((cs.sales_2024 / cs.sales_2022), 1/2.0) - 1)), 6), 0) AS projected_sales_2030
FROM cagr_sales cs
JOIN top_states ts ON cs.state = ts.state
WHERE cs.sales_2022 > 0;


#Estimate the revenue growth rate of 4-wheeler and 2-wheelers EVs in India for 2022 vs 2024 and 2023 vs 2024, assuming an average unit price.
WITH sales_by_year AS (
    SELECT vehicle_category, dd.fiscal_year,
           SUM(ev.electric_vehicles_sold) AS total_units_sold
    FROM electric_vehicle_sales_by_maker ev
    JOIN dim_date dd ON ev.date = dd.date
    WHERE dd.fiscal_year IN ('2022', '2023', '2024')
      AND ev.vehicle_category IN ('2-Wheelers', '4-Wheelers')
    GROUP BY vehicle_category, dd.fiscal_year
),
revenue_estimates AS (
    SELECT vehicle_category, fiscal_year,
           CASE 
               WHEN vehicle_category = '2-Wheelers' THEN total_units_sold * 100000
               WHEN vehicle_category = '4-Wheelers' THEN total_units_sold * 1500000
           END AS estimated_revenue
    FROM sales_by_year
)
SELECT vehicle_category, 
       SUM(CASE WHEN fiscal_year = '2022' THEN estimated_revenue END) AS revenue_2022,
       SUM(CASE WHEN fiscal_year = '2023' THEN estimated_revenue END) AS revenue_2023,
       SUM(CASE WHEN fiscal_year = '2024' THEN estimated_revenue END) AS revenue_2024,
       ROUND((SUM(CASE WHEN fiscal_year = '2024' THEN estimated_revenue END) - SUM(CASE WHEN fiscal_year = '2022' THEN estimated_revenue END)) / SUM(CASE WHEN fiscal_year = '2022' THEN estimated_revenue END) * 100, 2) AS growth_rate_2022_to_2024,
       ROUND((SUM(CASE WHEN fiscal_year = '2024' THEN estimated_revenue END) - SUM(CASE WHEN fiscal_year = '2023' THEN estimated_revenue END)) / SUM(CASE WHEN fiscal_year = '2023' THEN estimated_revenue END) * 100, 2) AS growth_rate_2023_to_2024
FROM revenue_estimates
GROUP BY vehicle_category;








