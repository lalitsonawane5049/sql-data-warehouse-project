/*
================================================================================
DDL Script : Create Gold Layer
================================================================================
Script Purpose:
  This script creates for the Gold layer in the data warehouse.
  The Gold layer represents the final dimension and fact tables(Star schema)

  Each view performs transformation and combines data from the silver layer
  to produce a clean, enriched, and business-ready dataset.

Usage :
  These views can be queries directly for analytics and reporting.
================================================================================
*/
--==============================================================================
--Create Dimension: gold.dim_customers
--==============================================================================
IF OBJECT_ID('gold.dim_customers','V') IS NOT NULL
  DROP VIEW gold.dim_customers;
GO
Create VIEW gold.dim_customers as (
Select 
	ROW_NUMBER() OVER(ORDER BY cst_id ) AS customer_key,
	ci.[cst_id] As customer_id,
	ci.[cst_key] AS customer_number,
	ci.[cst_firstname] As first_name,
	ci.[cst_lastname] As last_name,
	la.cntry as country,
	ci.[cst_marital_status] as marital_status,
	CASE 
		WHEN ci.cst_gndr  != 'N/A' THEN ci.cst_gndr -- CRM is the Master for gender INFO
		ELSE COALESCE(ca.gen,'N/A')
	END as gender,
	ca.bdate as birthdate,
	ci.[cst_create_date] as create_date	
From silver.crm_cust_info as ci
LEFT JOIN silver.erp_cust_az12 ca
on ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
on ci.cst_key = la.cid )
  
--==============================================================================
--Create Dimension: gold.dim_customers
--==============================================================================
IF OBJECT_ID('gold.dim_product','V') IS NOT NULL
  DROP VIEW gold.dim_product;
GO
Create view gold.dim_products as(
select 
	ROW_NUMBER() OVER(Order by pn.prd_start_dt,pn.prd_key) AS product_key, 
	pn.[prd_id] AS product_id,
	pn.[prd_key] AS product_number,
	pn.[prd_nm] AS product_name,
	pn.[cat_id] AS category_id,
	pc.cat As category,
	pc.subcat AS sub_category,
	pc.maintenance,
	pn.[prd_cost] As cost,
	pn.[prd_line] AS product_line,
	pn.[prd_start_dt] AS [start_date] 
from silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
On pn.cat_id = pc.id
Where prd_end_dt is NULL)-- Filter out all historical data

  --==============================================================================
--Create Dimension: gold.dim_customers
--==============================================================================
IF OBJECT_ID('gold.fact_sales','V') IS NOT NULL
    DROP View gold.fact_sales
 GO 
CREATE VIEW gold.fact_sales AS
SELECT
	[sls_ord_num] AS order_number,
	pr.product_key, -- surogate key
	cu.customer_key, --surrogate key
	[sls_order_dt] AS order_date ,
	[sls_ship_dt] AS shipping_date,
	[sls_due_dt] AS due_date,
	[sls_sales] AS sales_amount,
	[sls_quantity] AS quantity,
	[sls_price] as price
from silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id = cu.customer_id
