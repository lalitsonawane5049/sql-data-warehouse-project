/*
==================================================================================================
Quality Checks
===================================================================================================
Script Purpose:
  This script performs various quality checks for data consistency, accuracy, and standardization across the 'silver' schemas. It includes checks for;
  -Null or duplicates primary keys.
  -Unwanted spaces in string fields.
-Data standardization and consistency
-Invalid date ranges and orders.
-Data consistency between related fields.

Usage Notes :
  -Run these checks after data loading silver Layer.
  -Investigate and resolve any discrepancies found during the checks.
==================================================================================================
*/


--================================================================================
--Quality check for bronze.crm_cust_info
--================================================================================
--Check For Nulls or Duplicates in primary Key
--Expectation: No Result
select 
	cst_id,
	count(*)
from bronze.crm_cust_info
group by cst_id having count(cst_id) >  1 OR cst_id is NULL;

-- Check for unwanted Spaces
--Expected Result : No Result
Select 
	cst_lastname as lastname
from bronze.crm_cust_info
where cst_firstname != TRIM(cst_firstname)

Select 
	cst_lastname as lastname
from bronze.crm_cust_info
where cst_lastname != TRIM(cst_lastname)

Select 
	cst_gndr as gender
from bronze.crm_cust_info
where cst_gndr != TRIM(cst_gndr);

Select 
	cst_key as keys
from bronze.crm_cust_info
where cst_key != TRIM(cst_key);

--Data Standardization & Consistency
Select DISTINCT cst_gndr
from bronze.crm_cust_info;

select DISTINCT cst_marital_status
from bronze.crm_cust_info;

select * from bronze.crm_cust_info
where cst_marital_status is null;

--=================================================================================
--Quality check for silver.crm_cust_info
--=================================================================================
--Check For Nulls or Duplicates in primary Key
--Expectation: No Result
select 
	cst_id,
	count(*)
from silver.crm_cust_info
group by cst_id having count(cst_id) >  1 OR cst_id is NULL;

-- Check for unwanted Spaces
--Expected Result : No Result
Select 
	cst_lastname as lastname
from silver.crm_cust_info
where cst_firstname != TRIM(cst_firstname)

Select 
	cst_lastname as lastname
from silver.crm_cust_info
where cst_lastname != TRIM(cst_lastname)

Select 
	cst_gndr as gender
from silver.crm_cust_info
where cst_gndr != TRIM(cst_gndr);

Select 
	cst_key as keys
from silver.crm_cust_info
where cst_key != TRIM(cst_key);

--Data Standardization & Consistency
Select DISTINCT cst_gndr
from silver.crm_cust_info;

select DISTINCT cst_marital_status
from silver.crm_cust_info;


select * from bronze.crm_cust_info
where cst_id = 29466;

--=================================================================================
--Quality check for bronze.crm_prd_info
--=================================================================================
--Check For NULL or duplicates in Primary key
--Expectation: NO Result
select 
	prd_id,
	count(*)
from bronze.crm_prd_info
group by prd_id having count(*) > 1 OR prd_id is null;

--Check for unwanted Spaces
--Expectation: No Results
Select prd_nm
from bronze.crm_prd_info
where TRIM(prd_nm) != prd_nm;

-- Check for NULLs or negative Numbers
--Expectation: No Results
Select prd_cost
from bronze.crm_prd_info
where prd_cost < 0 OR prd_cost is NULL;

--Data Standardization & Consistency
Select DISTINCT prd_line
from bronze.crm_prd_info;

--Check for Invalid Date Orders , End date must not be earlier than the start date.
Select * 
From bronze.crm_prd_info
Where prd_end_dt < prd_start_dt;

--===============================================================================
--Quality check for silver.crm_prd_info
--===============================================================================
--Check For NULL or duplicates in Primary key
--Expectation: NO Result
select 
	prd_id,
	count(*)
from silver.crm_prd_info
group by prd_id having count(*) > 1 OR prd_id is null;

--Check for unwanted Spaces
--Expectation: No Results
Select prd_nm
from silver.crm_prd_info
where TRIM(prd_nm) != prd_nm;

-- Check for NULLs or negative Numbers
--Expectation: No Results
Select prd_cost
from silver.crm_prd_info
where prd_cost < 0 OR prd_cost is NULL;

--Data Standardization & Consistency
Select DISTINCT prd_line
from silver.crm_prd_info;

--Check for Invalid Date Orders , End date must not be earlier than the start date.
Select * 
From silver.crm_prd_info
Where prd_end_dt < prd_start_dt;

--=================================================================================
--Quality Check for bronze.crm_sales_details
--=================================================================================
--Check for unwanted spaces
select sls_ord_num 
from bronze.crm_sales_details
where sls_ord_num != TRIM(sls_ord_num);

select sls_prd_key 
from bronze.crm_sales_details
where sls_prd_key != TRIM(sls_prd_key);

--Check for the invalid date like negative or zero
--zero should be replaced by NULL. 
--Length should not be less than or greater than 8 : 20040930
select 
NULLIF(sls_order_dt,0) 
from bronze.crm_sales_details
where sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 OR sls_order_dt > 20500101 OR sls_order_dt < 19000101;;

select 
NULLIF(sls_ship_dt,0) 
from bronze.crm_sales_details
where sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 OR sls_ship_dt > 20500101 OR sls_ship_dt < 19000101;;

select 
NULLIF(sls_due_dt,0) 
from bronze.crm_sales_details
where sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 OR sls_due_dt > 20500101 OR sls_due_dt < 19000101;;

--Order date should be smaller than ship_dt and due_dt
Select sls_order_dt from bronze.crm_sales_details 
where sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;
select * from bronze.crm_sales_details;

--sales = quantity * price;
--IN sales , quantity , price negative , null , zeroes not allowed.
select DISTINCT
	sls_sales,
	sls_quantity,
	sls_price
from bronze.crm_sales_details
where sls_sales != sls_quantity * sls_price 
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL 
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
Order by sls_sales,sls_quantity,sls_price;

--================================================================================
--Quality Check for silver.crm_sales_details
--================================================================================
--Check for unwanted spaces
select sls_ord_num 
from silver.crm_sales_details
where sls_ord_num != TRIM(sls_ord_num);

select sls_prd_key 
from silver.crm_sales_details
where sls_prd_key != TRIM(sls_prd_key);

--Order date should be smaller than ship_dt and due_dt
Select sls_order_dt from silver.crm_sales_details 
where sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

--sales = quantity * price;
--IN sales , quantity , price negative , null , zeroes not allowed.
select DISTINCT
	sls_sales,
	sls_quantity,
	sls_price
from silver.crm_sales_details
where sls_sales != sls_quantity * sls_price 
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL 
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
Order by sls_sales,sls_quantity,sls_price;

--================================================================================
--Quality check in bronze.erp_loc_a101
--================================================================================
--Data Standardization & consistency
select distinct cntry
from bronze.erp_loc_a101;

--================================================================================
--Quality check in silver.erp_loc_a101
--================================================================================
--Data Standardization & consistency
select distinct cntry
from silver.erp_loc_a101;

--================================================================================
--Quality check for bronze.erp_cust_az12
--================================================================================
--check which id do not match pattern 
select count(*) ros from bronze.erp_cust_az12 where cid NOT LIKE 'NAS%';
select count(*) ros from bronze.erp_cust_az12 where LEN(cid)!= 13;

--Check bdate which arein future.
select distinct bdate from bronze.erp_cust_az12 where bdate > GETDATE()

--Data Standardization and normalization select distinct gender.
select distinct gen from bronze.erp_cust_az12;

--================================================================================
--Quality check for silver.erp_cust_az12
--================================================================================

--check which id do not match pattern 
select count(*) ros from silver.erp_cust_az12 where cid NOT LIKE 'NAS%';
select count(*) ros from silver.erp_cust_az12 where LEN(cid)!= 13;

--Check bdate which are in future.
select distinct bdate from silver.erp_cust_az12 where bdate > GETDATE()

--Data Standardization and normalization select distinct gender.
select distinct gen from silver.erp_cust_az12;
select count(*) from silver.erp_cust_az12;
select count(*) from bronze.erp_cust_az12;

--================================================================================
--Quality Checks for bronze.erp_px_cat_g1v2
--================================================================================
--check unwanted spaces
--Expected result : NO
select cat
from bronze.erp_px_cat_g1v2
where cat != TRIM(cat);

select subcat
from bronze.erp_px_cat_g1v2
where subcat != TRIM(subcat);

select maintenance
from bronze.erp_px_cat_g1v2
where maintenance != TRIM(maintenance);

-- Data standardization and consistency
select Distinct cat from bronze.erp_px_cat_g1v2;
select Distinct subcat from bronze.erp_px_cat_g1v2;
select Distinct maintenance from bronze.erp_px_cat_g1v2;
--Table has no quality issues

--================================================================================
--Quality Checks for silver.erp_px_cat_g1v2
--================================================================================
--check unwanted spaces
--Expected result : NO
select cat
from silver.erp_px_cat_g1v2
where cat != TRIM(cat);

select subcat
from silver.erp_px_cat_g1v2
where subcat != TRIM(subcat);

select maintenance
from silver.erp_px_cat_g1v2
where maintenance != TRIM(maintenance);

-- Data standardization and consistency
select Distinct cat from silver.erp_px_cat_g1v2;
select Distinct subcat from silver.erp_px_cat_g1v2;
select Distinct maintenance from silver.erp_px_cat_g1v2;
--Table has no quality issues




